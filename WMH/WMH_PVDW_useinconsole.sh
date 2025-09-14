#!/bin/bash
# Script to split WMH mask into PVWMH and DWMH
# Usage: WMH_PVDW.sh <WMH_MASK> <VENT_BIN>

# ==============================
# Input arguments
# ==============================
WMH_MASK="$1"
VENT_BIN="$2"

if [[ -z "$WMH_MASK" || -z "$VENT_BIN" ]]; then
    echo "Usage: $0 <WMH_MASK> <VENT_BIN>"
    exit 1
fi

# ==============================
# Setup
# ==============================
BASEDIR=$(dirname "$WMH_MASK")
OUTPUT_DIR="${BASEDIR}/output"
mkdir -p "$OUTPUT_DIR"

echo "WMH mask: $WMH_MASK"
echo "Ventricle mask: $VENT_BIN"
echo "Output directory: $OUTPUT_DIR"

# ==============================
# Step 1. Ensure WMH is binary
# ==============================
WMH_BIN="${OUTPUT_DIR}/WMH_bin.nii.gz"
fslmaths "$WMH_MASK" -bin "$WMH_BIN"
echo "Binarized WMH mask saved to: $WMH_BIN"

# ==============================
# Step 2. Create initial PV region (10 mm from ventricles)
# ==============================
PV_INIT="${OUTPUT_DIR}/PV_region_init.nii.gz"
fslmaths "$VENT_BIN" -dilM -dilM -dilM -dilM -dilM \
-dilM -dilM -dilM -dilM -dilM "$PV_INIT"

# ==============================
# Step 3. Initial PVWMH mask
# ==============================
PVWMH_INIT="${OUTPUT_DIR}/PVWMH_init.nii.gz"
fslmaths "$WMH_BIN" -mas "$PV_INIT" "$PVWMH_INIT"

# ==============================
# Step 4. Iteratively grow PVWMH to capture connected clusters
# ==============================
PVWMH_GROW="${OUTPUT_DIR}/PVWMH_grow.nii.gz"
cp "$PVWMH_INIT" "$PVWMH_GROW"

changed=1
iter=1
while [[ $changed -eq 1 ]]; do
    echo "Iteration $iter: Growing PVWMH..."
    TMP_GROW="${OUTPUT_DIR}/PVWMH_tmp.nii.gz"
    
    # Dilate current PVWMH
    fslmaths "$PVWMH_GROW" -dilM "$TMP_GROW"
    
    # Intersect dilated region with WMH
    fslmaths "$TMP_GROW" -mas "$WMH_BIN" "$TMP_GROW"
    
    # Add new voxels to PVWMH
    fslmaths "$PVWMH_GROW" -add "$TMP_GROW" -bin "$TMP_GROW"
    
    # Check if new voxels added
    old_vox=$(fslstats "$PVWMH_GROW" -V | awk '{print $1}')
    new_vox=$(fslstats "$TMP_GROW" -V | awk '{print $1}')
    
    if [[ "$new_vox" -eq "$old_vox" ]]; then
        changed=0
        echo "No new voxels added. Stopping."
    else
        mv "$TMP_GROW" "$PVWMH_GROW"
        ((iter++))
    fi
done

echo "Final PVWMH mask saved to: $PVWMH_GROW"

# ==============================
# Step 5. Define DWMH (WMH not in PVWMH)
# ==============================
DWMH="${OUTPUT_DIR}/DWMH.nii.gz"
fslmaths "$WMH_BIN" -sub "$PVWMH_GROW" -bin "$DWMH"

echo "Final DWMH mask saved to: $DWMH"
echo "All outputs stored in: $OUTPUT_DIR"
