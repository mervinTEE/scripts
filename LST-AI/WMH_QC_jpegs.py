import os
import numpy as np
import nibabel as nib
import matplotlib.pyplot as plt

def generate_wmh_qc_jpeg(flair_path, wmh_path, output_path, num_slices=16):
    # Load images
    flair_nii = nib.load(flair_path)
    wmh_nii = nib.load(wmh_path)

    flair_data = flair_nii.get_fdata()
    wmh_data = wmh_nii.get_fdata()

    # Check dimensions match
    assert flair_data.shape == wmh_data.shape, "FLAIR and WMH volumes must have the same shape."

    # Determine slice indices across axial plane (3rd dimension)
    z_slices = np.linspace(0, flair_data.shape[2]-1, num_slices, dtype=int)

    # Create 4x4 grid
    fig, axes = plt.subplots(4, 4, figsize=(12, 12))
    plt.subplots_adjust(wspace=0.0, hspace=0.0)

    for idx, z in enumerate(z_slices):
        row, col = divmod(idx, 4)
        ax = axes[row, col]

        flair_slice = np.rot90(flair_data[:, :, z])
        wmh_slice = np.rot90(wmh_data[:, :, z])

        ax.imshow(flair_slice, cmap='gray')
        ax.imshow(wmh_slice, cmap='red', alpha=0.4)  # Overlay WMH

        ax.axis('off')

    # Save as JPEG
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, bbox_inches='tight', pad_inches=0, dpi=150)
    plt.close()
    print(f"Saved: {output_path}")


    generate_wmh_qc_jpeg('/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/LSTAI_Y2/sub-HD001/temp/FLAIR.nii.gz', '/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/LSTAI_Y2/sub-HD001/temp/WMH.nii.gz', '/home/admin/Downloads/subject001_wmhqc.jpeg')