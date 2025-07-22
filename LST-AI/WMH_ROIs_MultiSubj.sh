#!/bin/bash
export WMHROOT=/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/y4y5
export WMHROOT=/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/y2


# Set path to atlas folder
export ATLASFOLDER=/home/admin/Desktop/MRI/MNI
export WMHROOT=/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/bl
OUTPUT_CSV="WMH_PVWM_DWM_volumes.csv"

# Step 1: Run once — generate PVWM/DWM masks if not already present
# Step 1: Run once — generate PVWM/DWM masks if not already present
if [ ! -f "$ATLASFOLDER/pvwm_in_wm.nii.gz" ] || [ ! -f "$ATLASFOLDER/dwm_in_wm.nii.gz" ]; then
    echo "Generating atlas-based PVWM and DWM masks..."
    
    # Generate lateral ventricle masks
    fslmaths $FSLDIR/data/atlases/HarvardOxford/HarvardOxford-sub-maxprob-thr0-1mm.nii.gz -thr 3 -uthr 3 -bin $ATLASFOLDER/latvent_L.nii.gz
    fslmaths $FSLDIR/data/atlases/HarvardOxford/HarvardOxford-sub-maxprob-thr0-1mm.nii.gz -thr 14 -uthr 14 -bin $ATLASFOLDER/latvent_R.nii.gz
    fslmaths $ATLASFOLDER/latvent_R.nii.gz -add $ATLASFOLDER/latvent_L.nii.gz -bin $ATLASFOLDER/ventricles_bin.nii.gz
    
    # Create distance map from ventricles
    distancemap -i $ATLASFOLDER/ventricles_bin.nii.gz -o $ATLASFOLDER/distmap.nii.gz
    
    # PVWM masks
    fslmaths $ATLASFOLDER/distmap.nii.gz -uthr 10 $ATLASFOLDER/pvwm_mask.nii.gz
    fslmaths $ATLASFOLDER/distmap.nii.gz -uthr 13 $ATLASFOLDER/pvwm_mask_13mm.nii.gz
    fslmaths $ATLASFOLDER/distmap.nii.gz -uthr 15 $ATLASFOLDER/pvwm_mask_15mm.nii.gz
    
    # DWM masks
    fslmaths $ATLASFOLDER/distmap.nii.gz -thr 10 $ATLASFOLDER/dwm_mask.nii.gz
    fslmaths $ATLASFOLDER/distmap.nii.gz -thr 13 $ATLASFOLDER/dwm_mask_13mm.nii.gz
    fslmaths $ATLASFOLDER/distmap.nii.gz -thr 15 $ATLASFOLDER/dwm_mask_15mm.nii.gz
    
    # Generate WM mask from FAST
    fast -t 1 -n 3 -H 0.1 -I 4 -l 20.0 -g -o $ATLASFOLDER/mni_fast $ATLASFOLDER/MNI152_T1_1mm.nii.gz
    fslmaths $ATLASFOLDER/mni_fast_pve_2.nii.gz -thr 0.5 -bin $ATLASFOLDER/wm_mask.nii.gz
    
    # Multiply with WM mask to restrict PVWM/DWM to white matter
    fslmaths $ATLASFOLDER/pvwm_mask.nii.gz -mul $ATLASFOLDER/wm_mask.nii.gz $ATLASFOLDER/pvwm_in_wm.nii.gz
    fslmaths $ATLASFOLDER/pvwm_mask_13mm.nii.gz -mul $ATLASFOLDER/wm_mask.nii.gz $ATLASFOLDER/pvwm_in_wm_13mm.nii.gz
    fslmaths $ATLASFOLDER/pvwm_mask_15mm.nii.gz -mul $ATLASFOLDER/wm_mask.nii.gz $ATLASFOLDER/pvwm_in_wm_15mm.nii.gz
    
    fslmaths $ATLASFOLDER/dwm_mask.nii.gz -mul $ATLASFOLDER/wm_mask.nii.gz $ATLASFOLDER/dwm_in_wm.nii.gz
    fslmaths $ATLASFOLDER/dwm_mask_13mm.nii.gz -mul $ATLASFOLDER/wm_mask.nii.gz $ATLASFOLDER/dwm_in_wm_13mm.nii.gz
    fslmaths $ATLASFOLDER/dwm_mask_15mm.nii.gz -mul $ATLASFOLDER/wm_mask.nii.gz $ATLASFOLDER/dwm_in_wm_15mm.nii.gz
fi

# Step 2: Initialize output CSV
echo "subject_id,WMH_PVWM_ml,WMH_DWM_ml,WMH_PVWM_13mm_ml,WMH_DWM_13mm_ml,WMH_PVWM_15mm_ml,WMH_DWM_15mm_ml" > "$WMHROOT/$OUTPUT_CSV"

# Step 3: Process each subject and extract volumes
for subjdir in $WMHROOT/sub-*; do
    subj=$(basename "$subjdir")
    echo "Processing $subj..."
    
    WMH_MNI="$subjdir/${subj}_WMH_to_MNI.nii.gz"
    
    # Output files
    PVWM_OUT="$subjdir/WMH_PVWM.nii.gz"
    DWM_OUT="$subjdir/WMH_DWM.nii.gz"
    PVWM_13_OUT="$subjdir/WMH_PVWM_13mm.nii.gz"
    DWM_13_OUT="$subjdir/WMH_DWM_13mm.nii.gz"
    PVWM_15_OUT="$subjdir/WMH_PVWM_15mm.nii.gz"
    DWM_15_OUT="$subjdir/WMH_DWM_15mm.nii.gz"
    
    # Check WMH input
    if [ ! -f "$WMH_MNI" ]; then
        echo "  --> WMH MNI file not found for $subj, skipping."
        continue
    fi
    
    # Apply masks
    fslmaths "$WMH_MNI" -mas "$ATLASFOLDER/pvwm_in_wm.nii.gz" "$PVWM_OUT"
    fslmaths "$WMH_MNI" -mas "$ATLASFOLDER/dwm_in_wm.nii.gz" "$DWM_OUT"
    fslmaths "$WMH_MNI" -mas "$ATLASFOLDER/pvwm_in_wm_13mm.nii.gz" "$PVWM_13_OUT"
    fslmaths "$WMH_MNI" -mas "$ATLASFOLDER/dwm_in_wm_13mm.nii.gz" "$DWM_13_OUT"
    fslmaths "$WMH_MNI" -mas "$ATLASFOLDER/pvwm_in_wm_15mm.nii.gz" "$PVWM_15_OUT"
    fslmaths "$WMH_MNI" -mas "$ATLASFOLDER/dwm_in_wm_15mm.nii.gz" "$DWM_15_OUT"
    
    # Compute volumes (voxels → ml)
    vol_pvwm=$(fslstats "$PVWM_OUT" -V | awk '{print $2}')
    vol_dwm=$(fslstats "$DWM_OUT" -V | awk '{print $2}')
    vol_pvwm_13=$(fslstats "$PVWM_13_OUT" -V | awk '{print $2}')
    vol_dwm_13=$(fslstats "$DWM_13_OUT" -V | awk '{print $2}')
    vol_pvwm_15=$(fslstats "$PVWM_15_OUT" -V | awk '{print $2}')
    vol_dwm_15=$(fslstats "$DWM_15_OUT" -V | awk '{print $2}')
    
    # Convert to ml
    vol_pvwm_ml=$(echo "scale=3; $vol_pvwm / 1000" | bc)
    vol_dwm_ml=$(echo "scale=3; $vol_dwm / 1000" | bc)
    vol_pvwm_13_ml=$(echo "scale=3; $vol_pvwm_13 / 1000" | bc)
    vol_dwm_13_ml=$(echo "scale=3; $vol_dwm_13 / 1000" | bc)
    vol_pvwm_15_ml=$(echo "scale=3; $vol_pvwm_15 / 1000" | bc)
    vol_dwm_15_ml=$(echo "scale=3; $vol_dwm_15 / 1000" | bc)
    
    echo "  PVWM: $vol_pvwm_ml ml | DWM: $vol_dwm_ml ml"
    echo "  PVWM_13mm: $vol_pvwm_13_ml ml | DWM_13mm: $vol_dwm_13_ml ml"
    echo "  PVWM_15mm: $vol_pvwm_15_ml ml | DWM_15mm: $vol_dwm_15_ml ml"
    
    # Append to CSV
    echo "${subj},${vol_pvwm_ml},${vol_dwm_ml},${vol_pvwm_13_ml},${vol_dwm_13_ml},${vol_pvwm_15_ml},${vol_dwm_15_ml}" >> "$WMHROOT/$OUTPUT_CSV"
done

echo "✅ CSV summary written to: $WMHROOT/$OUTPUT_CSV"




# ===========================
export ATLASFOLDER=/home/admin/Desktop/MRI/MNI
export WMHROOT=/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/bl
export WMHROOT=/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/y2
export WMHROOT=/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/y4y5


# Step  4: Loop through each subject for Penumbra Volumes
PENUMBRA_CSV="$WMHROOT/WMH_Penumbra_Volumes.csv"
echo "subject_id,penumbra_4mm_ml,penumbra_8mm_ml,pvwm_4mm_ml,pvwm_8mm_ml,dwm_4mm_ml,dwm_8mm_ml,pvwm_ml,dwm_ml" > "$PENUMBRA_CSV"


for subjdir in $WMHROOT/sub-*; do
    subj=$(basename "$subjdir")
    echo "Processing $subj..."
    
    WMH_PROB="$subjdir/${subj}_WMH_to_MNI.nii.gz"
    WMH_BIN="$subjdir/${subj}_WMHbin_to_MNI.nii.gz"
    PVWM_OUT="$subjdir/${subj}_WMH_PVWM.nii.gz"
    DWM_OUT="$subjdir/${subj}_WMH_DWM.nii.gz"
    
    # Skip if WMH doesn't exist
    if [ ! -f "$WMH_PROB" ]; then
        echo "  --> WMH not found for $subj, skipping."
        continue
    fi
    
    # Step 3a: Binarize WMH map at 0.3
    fslmaths "$WMH_PROB" -thr 0.3 -bin "$WMH_BIN"
    
    # Step 3b: Mask PVWM and DWM
    fslmaths "$WMH_BIN" -mas $ATLASFOLDER/pvwm_in_wm.nii.gz "$PVWM_OUT"
    fslmaths "$WMH_BIN" -mas $ATLASFOLDER/dwm_in_wm.nii.gz "$DWM_OUT"
    
    # Step 3c: Extract WMH volumes
    vol_pvwm=$(fslstats "$PVWM_OUT" -V | awk '{print $2}')
    vol_dwm=$(fslstats "$DWM_OUT" -V | awk '{print $2}')
    vol_pvwm_ml=$(echo "scale=3; $vol_pvwm / 1000" | bc)
    vol_dwm_ml=$(echo "scale=3; $vol_dwm / 1000" | bc)
    
    # Step 4: Create penumbra masks
    pen4="$subjdir/${subj}_WMHinMNI_4mmpenumbra.nii.gz"
    pen8="$subjdir/${subj}_WMHinMNI_8mmpenumbra.nii.gz"
    
    # Dilate and subtract original to get 4mm/8mm rings
    fslmaths "$WMH_BIN" -kernel sphere 4 -dilM "$subjdir/temp_dil4.nii.gz"
    fslmaths "$subjdir/temp_dil4.nii.gz" -sub "$WMH_BIN" -mas $ATLASFOLDER/wm_mask.nii.gz "$pen4"
    
    fslmaths "$WMH_BIN" -kernel sphere 8 -dilM "$subjdir/temp_dil8.nii.gz"
    fslmaths "$subjdir/temp_dil8.nii.gz" -sub "$WMH_BIN" -mas $ATLASFOLDER/wm_mask.nii.gz "$pen8"
    
    # PVWM & DWM penumbras
    pvwm4="$subjdir/${subj}_WMHinMNI_PVWM_4mmpenumbra.nii.gz"
    pvwm8="$subjdir/${subj}_WMHinMNI_PVWM_8mmpenumbra.nii.gz"
    dwm4="$subjdir/${subj}_WMHinMNI_DWM_4mmpenumbra.nii.gz"
    dwm8="$subjdir/${subj}_WMHinMNI_DWM_8mmpenumbra.nii.gz"
    
    fslmaths "$pen4" -mas $ATLASFOLDER/pvwm_in_wm.nii.gz "$pvwm4"
    fslmaths "$pen8" -mas $ATLASFOLDER/pvwm_in_wm.nii.gz "$pvwm8"
    fslmaths "$pen4" -mas $ATLASFOLDER/dwm_in_wm.nii.gz "$dwm4"
    fslmaths "$pen8" -mas $ATLASFOLDER/dwm_in_wm.nii.gz "$dwm8"
    
    # Optional: Remove periventricular regions from penumbra masks
    VENT_MASK="/home/admin/Desktop/MRI/MNI/ventricles_bin.nii.gz"
    VENT_DIL="$subjdir/ventricles_dil.nii.gz"
    
    # Dilate ventricle mask slightly (e.g., 2mm)
    fslmaths "$VENT_MASK" -kernel sphere 2 -dilM "$VENT_DIL"
    
    # Subtract from penumbra masks
    for mask in "$pen4" "$pen8" "$pvwm4" "$pvwm8" "$dwm4" "$dwm8"; do
        temp_mask="$mask.tmp.nii.gz"
        fslmaths "$mask" -sub "$VENT_DIL" -thr 0 -bin "$temp_mask"
        mv "$temp_mask" "$mask"
    done
    
    # Step 4b: Extract penumbra volumes
    get_vol_ml() {
        file=$1
        if [ -f "$file" ]; then
            vox=$(fslstats "$file" -V | awk '{print $2}')
            echo "scale=3; $vox / 1000" | bc
        else
            echo "0"
        fi
    }
    
    vol_pen4=$(get_vol_ml "$pen4")
    vol_pen8=$(get_vol_ml "$pen8")
    vol_pvwm4=$(get_vol_ml "$pvwm4")
    vol_pvwm8=$(get_vol_ml "$pvwm8")
    vol_dwm4=$(get_vol_ml "$dwm4")
    vol_dwm8=$(get_vol_ml "$dwm8")
    
    echo "$subj,$vol_pen4,$vol_pen8,$vol_pvwm4,$vol_pvwm8,$vol_dwm4,$vol_dwm8,$vol_pvwm_ml,$vol_dwm_ml" >> "$PENUMBRA_CSV"
    
    # Clean temp
    rm -f "$subjdir/temp_dil4.nii.gz" "$subjdir/temp_dil8.nii.gz"
done

echo "✅ Finished. CSV summaries:"
echo "  --> WMH_PVWM_DWM_volumes.csv"
echo "  --> WMH_Penumbra_Volumes.csv"


# ===========================
#TESTING 13/15mm

# Variables - set these before running
export WMHROOT=/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/bl
export WMHROOT=/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/y2
export WMHROOT=/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/y4y5
export ATLASFOLDER=/home/admin/Desktop/MRI/MNI  # contains masks like pvwm_in_wm.nii.gz, pvwm_in_wm_13mm.nii.gz, etc.
VENT_MASK="/home/admin/Desktop/MRI/MNI/ventricles_bin.nii.gz"
OUTPUT_CSV="WMH_Penumbra_Volumes.csv"

# Initialize CSV with extended header for 13mm and 15mm masks
echo "subject_id,penumbra_4mm_ml,penumbra_8mm_ml,pvwm_4mm_ml,pvwm_8mm_ml,dwm_4mm_ml,dwm_8mm_ml,pvwm_13mm_4mm_ml,pvwm_13mm_8mm_ml,dwm_13mm_4mm_ml,dwm_13mm_8mm_ml,pvwm_15mm_4mm_ml,pvwm_15mm_8mm_ml,dwm_15mm_4mm_ml,dwm_15mm_8mm_ml,pvwm_ml,dwm_ml" > "$WMHROOT/$OUTPUT_CSV"

for subjdir in $WMHROOT/sub-*; do
    subj=$(basename "$subjdir")
    echo "Processing $subj..."
    
    WMH_PROB="$subjdir/${subj}_WMH_to_MNI.nii.gz"
    WMH_BIN="$subjdir/${subj}_WMHbin_to_MNI.nii.gz"
    PVWM_OUT="$subjdir/${subj}_WMH_PVWM.nii.gz"
    DWM_OUT="$subjdir/${subj}_WMH_DWM.nii.gz"
    
    # Skip if WMH probability file doesn't exist
    if [ ! -f "$WMH_PROB" ]; then
        echo "  --> WMH not found for $subj, skipping."
        continue
    fi
    
    # Step 3a: Binarize WMH map at 0.3 threshold
    fslmaths "$WMH_PROB" -thr 0.3 -bin "$WMH_BIN"
    
    # Step 3b: Mask PVWM and DWM
    fslmaths "$WMH_BIN" -mas $ATLASFOLDER/pvwm_in_wm.nii.gz "$PVWM_OUT"
    fslmaths "$WMH_BIN" -mas $ATLASFOLDER/dwm_in_wm.nii.gz "$DWM_OUT"
    
    # Step 3c: Extract PVWM and DWM volumes in ml
    vol_pvwm=$(fslstats "$PVWM_OUT" -V | awk '{print $2}')
    vol_dwm=$(fslstats "$DWM_OUT" -V | awk '{print $2}')
    vol_pvwm_ml=$(echo "scale=3; $vol_pvwm / 1000" | bc)
    vol_dwm_ml=$(echo "scale=3; $vol_dwm / 1000" | bc)
    
    # Step 4: Create penumbra masks (4mm and 8mm rings)
    pen4="$subjdir/${subj}_WMHinMNI_4mmpenumbra.nii.gz"
    pen8="$subjdir/${subj}_WMHinMNI_8mmpenumbra.nii.gz"
    
    fslmaths "$WMH_BIN" -kernel sphere 4 -dilM "$subjdir/temp_dil4.nii.gz"
    fslmaths "$subjdir/temp_dil4.nii.gz" -sub "$WMH_BIN" -mas $ATLASFOLDER/wm_mask.nii.gz "$pen4"
    
    fslmaths "$WMH_BIN" -kernel sphere 8 -dilM "$subjdir/temp_dil8.nii.gz"
    fslmaths "$subjdir/temp_dil8.nii.gz" -sub "$WMH_BIN" -mas $ATLASFOLDER/wm_mask.nii.gz "$pen8"
    
    # PVWM & DWM penumbra masks for 4mm and 8mm
    pvwm4="$subjdir/${subj}_WMHinMNI_PVWM_4mmpenumbra.nii.gz"
    pvwm8="$subjdir/${subj}_WMHinMNI_PVWM_8mmpenumbra.nii.gz"
    dwm4="$subjdir/${subj}_WMHinMNI_DWM_4mmpenumbra.nii.gz"
    dwm8="$subjdir/${subj}_WMHinMNI_DWM_8mmpenumbra.nii.gz"
    
    fslmaths "$pen4" -mas $ATLASFOLDER/pvwm_in_wm.nii.gz "$pvwm4"
    fslmaths "$pen8" -mas $ATLASFOLDER/pvwm_in_wm.nii.gz "$pvwm8"
    fslmaths "$pen4" -mas $ATLASFOLDER/dwm_in_wm.nii.gz "$dwm4"
    fslmaths "$pen8" -mas $ATLASFOLDER/dwm_in_wm.nii.gz "$dwm8"
    
    # Penumbra masks with 13mm PVWM/DWM masks
    pvwm13_4="$subjdir/${subj}_WMHinMNI_PVWM_13mm_4mmpenumbra.nii.gz"
    pvwm13_8="$subjdir/${subj}_WMHinMNI_PVWM_13mm_8mmpenumbra.nii.gz"
    dwm13_4="$subjdir/${subj}_WMHinMNI_DWM_13mm_4mmpenumbra.nii.gz"
    dwm13_8="$subjdir/${subj}_WMHinMNI_DWM_13mm_8mmpenumbra.nii.gz"
    
    fslmaths "$pen4" -mas $ATLASFOLDER/pvwm_in_wm_13mm.nii.gz "$pvwm13_4"
    fslmaths "$pen8" -mas $ATLASFOLDER/pvwm_in_wm_13mm.nii.gz "$pvwm13_8"
    fslmaths "$pen4" -mas $ATLASFOLDER/dwm_in_wm_13mm.nii.gz "$dwm13_4"
    fslmaths "$pen8" -mas $ATLASFOLDER/dwm_in_wm_13mm.nii.gz "$dwm13_8"
    
    # Penumbra masks with 15mm PVWM/DWM masks
    pvwm15_4="$subjdir/${subj}_WMHinMNI_PVWM_15mm_4mmpenumbra.nii.gz"
    pvwm15_8="$subjdir/${subj}_WMHinMNI_PVWM_15mm_8mmpenumbra.nii.gz"
    dwm15_4="$subjdir/${subj}_WMHinMNI_DWM_15mm_4mmpenumbra.nii.gz"
    dwm15_8="$subjdir/${subj}_WMHinMNI_DWM_15mm_8mmpenumbra.nii.gz"
    
    fslmaths "$pen4" -mas $ATLASFOLDER/pvwm_in_wm_15mm.nii.gz "$pvwm15_4"
    fslmaths "$pen8" -mas $ATLASFOLDER/pvwm_in_wm_15mm.nii.gz "$pvwm15_8"
    fslmaths "$pen4" -mas $ATLASFOLDER/dwm_in_wm_15mm.nii.gz "$dwm15_4"
    fslmaths "$pen8" -mas $ATLASFOLDER/dwm_in_wm_15mm.nii.gz "$dwm15_8"
    
    # Optional: Remove periventricular regions from penumbra masks by subtracting dilated ventricle mask
    VENT_DIL="$subjdir/ventricles_dil.nii.gz"
    fslmaths "$VENT_MASK" -kernel sphere 2 -dilM "$VENT_DIL"
    
    for mask in "$pen4" "$pen8" "$pvwm4" "$pvwm8" "$dwm4" "$dwm8" "$pvwm13_4" "$pvwm13_8" "$dwm13_4" "$dwm13_8" "$pvwm15_4" "$pvwm15_8" "$dwm15_4" "$dwm15_8"; do
        temp_mask="$mask.tmp.nii.gz"
        fslmaths "$mask" -sub "$VENT_DIL" -thr 0 -bin "$temp_mask"
        mv "$temp_mask" "$mask"
    done
    
    # Function to extract volume in ml
    get_vol_ml() {
        local file=$1
        if [ -f "$file" ]; then
            local vox=$(fslstats "$file" -V | awk '{print $2}')
            echo "scale=3; $vox / 1000" | bc
        else
            echo "0"
        fi
    }
    
    # Extract volumes for all masks
    vol_pen4=$(get_vol_ml "$pen4")
    vol_pen8=$(get_vol_ml "$pen8")
    
    vol_pvwm4=$(get_vol_ml "$pvwm4")
    vol_pvwm8=$(get_vol_ml "$pvwm8")
    vol_dwm4=$(get_vol_ml "$dwm4")
    vol_dwm8=$(get_vol_ml "$dwm8")
    
    vol_pvwm13_4=$(get_vol_ml "$pvwm13_4")
    vol_pvwm13_8=$(get_vol_ml "$pvwm13_8")
    vol_dwm13_4=$(get_vol_ml "$dwm13_4")
    vol_dwm13_8=$(get_vol_ml "$dwm13_8")
    
    vol_pvwm15_4=$(get_vol_ml "$pvwm15_4")
    vol_pvwm15_8=$(get_vol_ml "$pvwm15_8")
    vol_dwm15_4=$(get_vol_ml "$dwm15_4")
    vol_dwm15_8=$(get_vol_ml "$dwm15_8")
    
    # Append all to CSV
    echo "$subj,$vol_pen4,$vol_pen8,$vol_pvwm4,$vol_pvwm8,$vol_dwm4,$vol_dwm8,$vol_pvwm13_4,$vol_pvwm13_8,$vol_dwm13_4,$vol_dwm13_8,$vol_pvwm15_4,$vol_pvwm15_8,$vol_dwm15_4,$vol_dwm15_8,$vol_pvwm_ml,$vol_dwm_ml" >> "$WMHROOT/$OUTPUT_CSV"
    
    # Clean temp dilations
    rm -f "$subjdir/temp_dil4.nii.gz" "$subjdir/temp_dil8.nii.gz" "$VENT_DIL"
done

echo "✅ Finished. CSV summary:"
echo "  --> $WMHROOT/$OUTPUT_CSV"