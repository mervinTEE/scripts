#!/usr/bin/env python3
import os
import sys
import numpy as np
from PIL import Image
import nibabel as nib

def overlay_slices(flair_data, wmh_data, slices, alpha=0.7):
    slice_images = []
    for z in slices:
        flair_slice = flair_data[:, :, z]
        wmh_slice = wmh_data[:, :, z]

        # Red overlay for WMH
        overlay = np.zeros(flair_slice.shape + (3,), dtype=np.uint8)
        overlay[wmh_slice > 0] = [255, 0, 0]

        # Convert FLAIR to grayscale RGB
        flair_rgb = np.stack([flair_slice]*3, axis=-1)
        flair_rgb = ((flair_rgb - flair_rgb.min()) /
                     max(flair_rgb.max() - flair_rgb.min(), 1e-6) * 255).astype(np.uint8)

        # Blend FLAIR and WMH overlay
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
    print("Usage: python WMH_QC.py <BASE_DIR> <SUBJ_ID>")
    sys.exit(1)

base_dir = sys.argv[1]
subj = sys.argv[2]
tps = ["BL", "Y2", "Y4Y5"]

for tp in tps:
    subj_tp_dir = os.path.join(base_dir, tp, subj)
    if not os.path.exists(subj_tp_dir):
        continue

    flair_file = os.path.join(subj_tp_dir, "FLAIR_common_inMNI.nii.gz")
    wmh_file = os.path.join(subj_tp_dir, "WMH_common_inMNI_bin.nii.gz")

    if not os.path.exists(flair_file) or not os.path.exists(wmh_file):
        continue

    print(f"QC overlay for {subj} {tp}")

    flair_img = nib.load(flair_file)
    wmh_img = nib.load(wmh_file)
    flair_data = flair_img.get_fdata()
    wmh_data = wmh_img.get_fdata()

    # Choose 5 axial slices around middle
    z_mid = flair_data.shape[2] // 2
    slice_indices = [z_mid + i*10 for i in range(-2, 3)
                     if 0 <= z_mid + i*10 < flair_data.shape[2]]

    slices = overlay_slices(flair_data, wmh_data, slice_indices, alpha=0.7)

    qc_dir = os.path.join(base_dir, tp, "QC_JPEGs")
    os.makedirs(qc_dir, exist_ok=True)
    out_file = os.path.join(qc_dir, f"{subj}_{tp}_QC.jpg")

    save_concatenated(slices, out_file)
    print(f"Saved: {out_file}")

print("QC images complete. ")
