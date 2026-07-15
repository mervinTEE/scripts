#!/usr/bin/env python3
"""
WMH QC: generate FLAIR+WMH overlay JPEGs for quick visual QC.

Directory layout expected:

  Multi timepoint (default):
    <ROOT>/<TIMEPOINT>/<SUBJ>/<flair_name>
    <ROOT>/<TIMEPOINT>/<SUBJ>/<wmh_name>
    QC JPEGs written to <ROOT>/<TIMEPOINT>/QC_JPEGs/

  Single timepoint:
    <ROOT>/<SUBJ>/<flair_name>
    <ROOT>/<SUBJ>/<wmh_name>
    QC JPEGs written to <ROOT>/QC_JPEGs/

Filename matching: --flair-name / --wmh-name are tried as exact filenames
first. If a subject folder doesn't have an exact match, each is looked up
by pattern instead (FLAIR: "*flair*.nii.gz"; WMH mask: "*wmh*bin*.nii.gz",
"*wmh*.nii.gz", "*seg-lst*.nii.gz", "*mask*.nii.gz", tried in that order).
The WMH mask is resolved first and excluded from the FLAIR search, so a
BIDS-style name like "..._space-flair_seg-lst.nii.gz" isn't mistaken for
the FLAIR image just because "flair" appears in it. A subject is skipped
with a printed WARNING if either file can't be found or the pattern match
is ambiguous (multiple candidates) -- it never silently guesses wrong.

Usage examples:
  # Multi timepoint, all subjects found under ROOT, default TP folders BL/Y2/Y4Y5
  python WMH_QC.py --root /data/WMH_project

  # Multi timepoint, custom timepoint folder names
  python WMH_QC.py --root /data/WMH_project --timepoints BL Y2 Y4Y5

  # Single timepoint layout (ROOT/SUBJ/*)
  python WMH_QC.py --root /data/WMH_project --single-timepoint

  # Restrict to specific subject(s) ("--subject" also works as an alias)
  python WMH_QC.py --root /data/WMH_project --subjects 0001 0002

  # Custom filenames / output location / slice count / grid columns
  python WMH_QC.py --root /data/WMH_project --flair-name FLAIR.nii.gz \
      --wmh-name WMH_bin.nii.gz --out-dir /data/WMH_project/QC --n-slices 15 --ncols 5

Slice selection: the FLAIR volumes here are not skull-stripped, so face,
sinus, and neck tissue are just as bright as brain parenchyma -- intensity
thresholding alone can't tell them apart. Instead, the --n-slices axial
slices are spread evenly across the WMH mask's own z-extent (padded 25%,
minimum 5 slices, clipped to the volume), so the grid stays anchored to
the lesion-bearing region of the brain regardless of volume size or extra
non-brain anatomy in the FOV. If a subject has no segmented lesions at
all, it falls back to trimming 15% off each end of the full volume --
a weaker heuristic that can still include some non-brain edge slices.
"""
import argparse
import fnmatch
import math
import os
import sys

import numpy as np
from PIL import Image
import nibabel as nib

FLAIR_PATTERNS = ["*flair*.nii.gz"]
WMH_PATTERNS = ["*wmh*bin*.nii.gz", "*wmh*.nii.gz", "*seg-lst*.nii.gz", "*seg*lst*.nii.gz", "*mask*.nii.gz"]


def overlay_slices(flair_data, wmh_data, slices, alpha=0.7):
    slice_images = []
    for z in slices:
        flair_slice = flair_data[:, :, z]
        wmh_slice = wmh_data[:, :, z]

        # Rotate slices 90 clockwise
        flair_slice = np.rot90(flair_slice, k=-1)
        wmh_slice = np.rot90(wmh_slice, k=-1)

        # Red overlay for WMH
        overlay = np.zeros(flair_slice.shape + (3,), dtype=np.uint8)
        overlay[wmh_slice > 0] = [255, 0, 0]

        # Convert FLAIR to grayscale RGB
        flair_rgb = np.stack([flair_slice] * 3, axis=-1)
        flair_rgb = ((flair_rgb - flair_rgb.min()) /
                     max(flair_rgb.max() - flair_rgb.min(), 1e-6) * 255).astype(np.uint8)

        # Blend FLAIR and WMH overlay
        blended = (flair_rgb * (1 - alpha) + overlay * alpha).astype(np.uint8)
        slice_images.append(Image.fromarray(blended))
    return slice_images


def save_grid(slice_images, out_file, ncols):
    ncols = max(1, min(ncols, len(slice_images)))
    nrows = math.ceil(len(slice_images) / ncols)
    width, height = slice_images[0].size

    grid_im = Image.new('RGB', (width * ncols, height * nrows))
    for idx, im in enumerate(slice_images):
        row, col = divmod(idx, ncols)
        grid_im.paste(im, (col * width, row * height))
    grid_im.save(out_file, 'JPEG')


def resolve_file(subj_dir, exact_name, patterns, label, exclude=()):
    """Find a NIfTI file in subj_dir: exact name first, else pattern fallback."""
    exact_path = os.path.join(subj_dir, exact_name)
    if os.path.exists(exact_path):
        return exact_path

    candidates = [
        f for f in os.listdir(subj_dir)
        if f != "QC_JPEGs" and f not in exclude
        and any(fnmatch.fnmatch(f.lower(), p) for p in patterns)
    ]
    if len(candidates) == 1:
        found = os.path.join(subj_dir, candidates[0])
        print(f"  auto-detected {label}: {candidates[0]} (no exact match for '{exact_name}')")
        return found
    if len(candidates) == 0:
        print(f"  WARNING: no {label} file found in {subj_dir} "
              f"(looked for '{exact_name}' and patterns {patterns})")
    else:
        print(f"  WARNING: ambiguous {label} match in {subj_dir}: {candidates} "
              f"-- specify --{label}-name explicitly")
    return None


def find_subjects(scan_dir):
    """Return sorted subject folder names directly under scan_dir."""
    if not os.path.isdir(scan_dir):
        return []
    return sorted(
        d for d in os.listdir(scan_dir)
        if os.path.isdir(os.path.join(scan_dir, d))
    )


def brain_z_bounds(flair_data, wmh_data, thresh_frac=0.05):
    """Find the axial slice range to center the QC grid on.

    FLAIR volumes here are not skull-stripped, so face/sinus/neck tissue is
    just as bright as brain parenchyma -- intensity thresholding alone can't
    tell them apart. Instead, anchor on the WMH lesion mask itself (this is
    a WMH QC tool, so the lesion-bearing slices are what actually matters),
    padded out to also show some lesion-free brain above/below the core
    lesion span. Falls back to trimming the outer edges of the full volume
    if a subject has no segmented lesions at all.
    """
    depth = flair_data.shape[2]
    wmh_counts = (wmh_data > 0).sum(axis=(0, 1))
    max_wmh = wmh_counts.max()

    if max_wmh > 0:
        core = np.where(wmh_counts > max_wmh * thresh_frac)[0]
        lo, hi = int(core.min()), int(core.max())
        pad = max(int(round((hi - lo + 1) * 0.25)), 5)
        return max(0, lo - pad), min(depth - 1, hi + pad)

    # No lesions found: fall back to trimming the outer edges of the volume,
    # which are most likely to be pure skull-base/vertex/background slices.
    trim = int(round(depth * 0.15))
    return trim, depth - 1 - trim


def qc_one(subj_dir, subj, label, flair_name, wmh_name, qc_dir, n_slices, alpha, ncols):
    print(f"QC overlay for {subj} {label}")

    # Resolve WMH first (its patterns are more specific), then exclude that
    # filename from the FLAIR search so BIDS space descriptors like
    # "space-flair_seg-lst.nii.gz" don't get mistaken for the FLAIR image.
    wmh_file = resolve_file(subj_dir, wmh_name, WMH_PATTERNS, "wmh")
    exclude = {os.path.basename(wmh_file)} if wmh_file else set()
    flair_file = resolve_file(subj_dir, flair_name, FLAIR_PATTERNS, "flair", exclude=exclude)

    if flair_file is None or wmh_file is None:
        return False

    # Force canonical orientation (RAS+)
    flair_img = nib.as_closest_canonical(nib.load(flair_file))
    wmh_img = nib.as_closest_canonical(nib.load(wmh_file))

    flair_data = flair_img.get_fdata()
    wmh_data = wmh_img.get_fdata()

    # Choose slices evenly spaced across the brain tissue range so the grid
    # is always centred on brain, regardless of volume size/padding.
    z_lo, z_hi = brain_z_bounds(flair_data, wmh_data)
    slice_indices = sorted(set(int(round(z)) for z in np.linspace(z_lo, z_hi, n_slices)))

    slices = overlay_slices(flair_data, wmh_data, slice_indices, alpha=alpha)

    os.makedirs(qc_dir, exist_ok=True)
    out_file = os.path.join(qc_dir, f"{subj}_{label}_QC.jpg")

    save_grid(slices, out_file, ncols)
    print(f"Saved: {out_file}")
    return True


def run_single_timepoint(root, subjects, flair_name, wmh_name, out_dir, n_slices, alpha, ncols):
    subjects = subjects or find_subjects(root)
    qc_dir = out_dir or os.path.join(root, "QC_JPEGs")

    processed = 0
    for subj in subjects:
        subj_dir = os.path.join(root, subj)
        if not os.path.isdir(subj_dir):
            continue
        if qc_one(subj_dir, subj, "QC", flair_name, wmh_name, qc_dir, n_slices, alpha, ncols):
            processed += 1
    return processed


def run_multi_timepoint(root, timepoints, subjects, flair_name, wmh_name, out_dir, n_slices, alpha, ncols):
    processed = 0
    for tp in timepoints:
        tp_dir = os.path.join(root, tp)
        if not os.path.isdir(tp_dir):
            continue

        tp_subjects = subjects or find_subjects(tp_dir)
        qc_dir = out_dir or os.path.join(tp_dir, "QC_JPEGs")

        for subj in tp_subjects:
            subj_dir = os.path.join(tp_dir, subj)
            if not os.path.isdir(subj_dir):
                continue
            if qc_one(subj_dir, subj, tp, flair_name, wmh_name, qc_dir, n_slices, alpha, ncols):
                processed += 1
    return processed


def parse_args():
    parser = argparse.ArgumentParser(
        description="Generate FLAIR+WMH overlay QC JPEGs for one or more subjects.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--root", required=True, help="Root directory to search for subject data.")
    parser.add_argument("--subjects", "--subject", nargs="+", default=None,
                         help="Specific subject folder name(s) to process. Default: auto-discover all.")
    parser.add_argument("--single-timepoint", action="store_true",
                         help="Treat --root as containing subject folders directly (ROOT/SUBJ/*) "
                              "instead of ROOT/TIMEPOINT/SUBJ/*.")
    parser.add_argument("--timepoints", nargs="+", default=["BL", "Y2", "Y4Y5"],
                         help="Timepoint folder names to search under --root (multi-timepoint mode only). "
                              "Default: BL Y2 Y4Y5.")
    parser.add_argument("--flair-name", default="FLAIR_common_inMNI.nii.gz",
                         help="FLAIR filename expected inside each subject folder.")
    parser.add_argument("--wmh-name", default="WMH_common_inMNI_bin.nii.gz",
                         help="WMH mask filename expected inside each subject folder.")
    parser.add_argument("--out-dir", default=None,
                         help="Directory to write QC JPEGs. Default: QC_JPEGs alongside subject data "
                              "(per-timepoint in multi mode, or under --root in single mode).")
    parser.add_argument("--n-slices", type=int, default=15,
                         help="Number of axial slices to render, spread evenly across the detected "
                              "brain tissue range (not the full volume). Default: 15.")
    parser.add_argument("--ncols", type=int, default=5,
                         help="Number of columns in the output grid (rows = ceil(n-slices / ncols)). Default: 5.")
    parser.add_argument("--alpha", type=float, default=0.7, help="WMH overlay opacity (0-1). Default: 0.7.")
    return parser.parse_args()


def main():
    args = parse_args()

    if not os.path.isdir(args.root):
        print(f"Root directory does not exist: {args.root}")
        sys.exit(1)

    if args.single_timepoint:
        processed = run_single_timepoint(
            args.root, args.subjects, args.flair_name, args.wmh_name,
            args.out_dir, args.n_slices, args.alpha, args.ncols,
        )
    else:
        processed = run_multi_timepoint(
            args.root, args.timepoints, args.subjects, args.flair_name, args.wmh_name,
            args.out_dir, args.n_slices, args.alpha, args.ncols,
        )

    print(f"QC images complete. {processed} overlay(s) generated.")


if __name__ == "__main__":
    main()
