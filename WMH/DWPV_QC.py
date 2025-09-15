#!/usr/bin/env python3
import os
import sys
import numpy as np
from PIL import Image
import nibabel as nib

def overlay_slices(flair_data, pv_data, dw_data, slices, alpha=0.7):
    slice_images = []
    for z in slices:
        flair_slice = flair_data[:, :, z]
        pv_slice    = pv_data[:, :, z]
        dw_slice    = dw_data[:, :, z]

        # Rotate slices 90° clockwise
        flair_slice = np.rot90(flair_slice, k=-1)
        pv_slice    = np.rot90(pv_slice, k=-1)
        dw_slice    = np.rot90(dw_slice, k=-1)

        # Convert FLAIR to grayscale RGB
        flair_rgb = np.stack([flair_slice]*3, axis=-1)
        flair_rgb = ((flair_rgb - flair_rgb.min()) /
                     max(flair_rgb.max() - flair_rgb.min(), 1e-6) * 255).astype(np.uint8)

        # Initialize overlay
        overlay = np.zeros_like(flair_rgb, dtype=np.uint8)

        # Red for PVWMH
        overlay[pv_slice > 0] = [255, 0, 0]
        # Blue for DWMH
        overlay[dw_slice > 0] = [0, 0, 255]
        # Magenta for overlap (priority over red/blue)
        overlap = (pv_slice > 0) & (dw_slice > 0)
        overlay[overlap] = [255, 0, 255]

        # Blend overlay onto FLAIR
        blended = (flair_rgb * (1 - alpha) + overlay * alpha).astype(np.uint8)
        slice_images.append(Image.fromarray(blended))
    return slice_images

def save_concatenated(slice_images, out_file):
    widths, heights = zip(*(im.size for im in slice_images))
    total_width = sum(widths)
    max_height = max(heights)

    new_im = Image.new('RGB', (total_width, max_height))
    x_offset = 0
    for im in slice_images:
        new_im.paste(im, (x_offset, 0))
        x_offset += im.size[0]
    new_im.save(out_file, 'JPEG')

if len(sys.argv) < 3:
    print("Usage: python DWPV_QC_simple.py <BASE_DIR> <SUBJ_ID>")
    sys.exit(1)

base_dir = sys.argv[1]
subj = sys.argv[2]
tps = ["BL", "Y2", "Y4Y5"]

for tp in tps:
    subj_tp_dir = os.path.join(base_dir, tp, subj, "DWPV_output")
    if not os.path.exists(subj_tp_dir):
        continue

    flair_file = os.path.join(base_dir, tp, subj, "FLAIR_common_inMNI.nii.gz")
    pv_file    = os.path.join(subj_tp_dir, "PVWMH.nii.gz")
    dw_file    = os.path.join(subj_tp_dir, "DWMH.nii.gz")

    if not all(os.path.exists(f) for f in [flair_file, pv_file, dw_file]):
        continue

    print(f"QC overlay for {subj} {tp}")

    # Load images and force canonical orientation
    flair_img = nib.as_closest_canonical(nib.load(flair_file))
    pv_img    = nib.as_closest_canonical(nib.load(pv_file))
    dw_img    = nib.as_closest_canonical(nib.load(dw_file))

    flair_data = flair_img.get_fdata()
    pv_data    = pv_img.get_fdata()
    dw_data    = dw_img.get_fdata()

    # Choose 4 axial slices: midpoint and superior (+10, +20, +30)
    z_mid = flair_data.shape[2] // 2
    slice_indices = [z_mid + i for i in [0, 10, 20, 30]
                     if 0 <= z_mid + i < flair_data.shape[2]]

    slices = overlay_slices(flair_data, pv_data, dw_data, slice_indices, alpha=0.7)

    qc_dir = os.path.join(base_dir, tp, "QC_JPEGs")
    os.makedirs(qc_dir, exist_ok=True)
    out_file = os.path.join(qc_dir, f"{subj}_{tp}_DWPV_QC.jpg")

    save_concatenated(slices, out_file)
    print(f"✅ Saved: {out_file}")

print("QC images complete.")
