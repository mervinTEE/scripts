#!/bin/bash
# Script to split WMH masks into PVWMH and DWMH for multiple subjects and timepoints
# Usage: WMH_PVDW_multiTP.sh <VENT_BIN> <BASE_DIR> <SUBJ1> [<SUBJ2> ...]
# Example:
# bash WMH_PVDW_multiTP.sh /path/to/vent_bin.nii.gz /mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal sub-HD001 sub-HD002

set -euo pipefail

VENT_BIN="$1"
BASE_PATH="$2"
shift 2
SUBJECTS=("$@")

TP_DIRS=("BL" "Y2" "Y4Y5")

for SUBJ in "${SUBJECTS[@]}"; do
    echo "===================="
    echo "Processing subject: $SUBJ"
    echo "===================="
    
    for TP in "${TP_DIRS[@]}"; do
        SUBJ_TP_DIR="${BASE_PATH}/${TP}/${SUBJ}"
        echo "--- Processing TP: $TP ---"
        echo "Subject TP directory: $SUBJ_TP_DIR"
        
        # Check directory exists
        if [[ ! -d "$SUBJ_TP_DIR" ]]; then
            echo "TP directory does not exist: $SUBJ_TP_DIR. Skipping this TP."
            continue
        fi
        
        # Prioritize edited or annotated WMH masks
        WMH_MASK=""
        if [[ -f "${SUBJ_TP_DIR}/sub-X_ses-Y_space-flair_seg-lst_edited_in_MNI_bin.nii.gz" ]]; then
            WMH_MASK="${SUBJ_TP_DIR}/sub-X_ses-Y_space-flair_seg-lst_edited_in_MNI_bin.nii.gz"
            elif [[ -f "${SUBJ_TP_DIR}/sub-X_ses-Y_space-flair_desc-annotated_seg-lst_in_MNI_bin.nii.gz" ]]; then
            WMH_MASK="${SUBJ_TP_DIR}/sub-X_ses-Y_space-flair_desc-annotated_seg-lst_in_MNI_bin.nii.gz"
            elif [[ -f "${SUBJ_TP_DIR}/sub-X_ses-Y_space-flair_seg-lst_in_MNI_bin.nii.gz" ]]; then
            WMH_MASK="${SUBJ_TP_DIR}/sub-X_ses-Y_space-flair_seg-lst_in_MNI_bin.nii.gz"
        fi
        
        if [[ -z "$WMH_MASK" ]]; then
            echo "No WMH mask found for $SUBJ TP $TP. Skipping this TP."
            continue
        else
            echo "WMH mask found: $WMH_MASK"
        fi
        
        # Setup output directory
        OUTPUT_DIR="${SUBJ_TP_DIR}/DWPV_output"
        mkdir -p "$OUTPUT_DIR"
        
        echo "Step 1: Binarize WMH mask..."
        WMH_BIN="${OUTPUT_DIR}/WMH_bin.nii.gz"
        fslmaths "$WMH_MASK" -bin "$WMH_BIN"
        
        echo "Step 2: Create initial PV region (10 mm from ventricles)..."
        PV_INIT="${OUTPUT_DIR}/PV_region_init.nii.gz"
        fslmaths "$VENT_BIN" -dilM -dilM -dilM -dilM -dilM -dilM -dilM -dilM -dilM -dilM "$PV_INIT"
        
        echo "Step 3: Initial PVWMH mask..."
        PVWMH_INIT="${OUTPUT_DIR}/PVWMH_init.nii.gz"
        fslmaths "$WMH_BIN" -mas "$PV_INIT" "$PVWMH_INIT"
        
        echo "Step 4: Iteratively grow PVWMH..."
        PVWMH_GROW="${OUTPUT_DIR}/PVWMH.nii.gz"
        cp "$PVWMH_INIT" "$PVWMH_GROW"
        
        changed=1
        iter=1
        while [[ $changed -eq 1 ]]; do
            echo "Iteration $iter: Growing PVWMH..."
            TMP_GROW="${OUTPUT_DIR}/PVWMH_tmp.nii.gz"
            
            fslmaths "$PVWMH_GROW" -dilM "$TMP_GROW"
            fslmaths "$TMP_GROW" -mas "$WMH_BIN" "$TMP_GROW"
            fslmaths "$PVWMH_GROW" -add "$TMP_GROW" -bin "$TMP_GROW"
            
            old_vox=$(fslstats "$PVWMH_GROW" -V | awk '{print $1}')
            new_vox=$(fslstats "$TMP_GROW" -V | awk '{print $1}')
            
            if [[ "$new_vox" -eq "$old_vox" ]]; then
                changed=0
                echo "No new voxels added. Stopping iteration."
            else
                mv "$TMP_GROW" "$PVWMH_GROW"
                ((iter++))
            fi
        done
        
        echo "Step 5: Define DWMH (WMH not in PVWMH)..."
        DWMH="${OUTPUT_DIR}/DWMH.nii.gz"
        fslmaths "$WMH_BIN" -sub "$PVWMH_GROW" -bin "$DWMH"
        
        echo "✅ TP $TP complete. Outputs:"
        echo "PVWMH: $PVWMH_GROW"
        echo "DWMH: $DWMH"
        echo "-----------------------------"
    done
    
    echo "All available TPs processed for subject: $SUBJ"
done

echo "All subjects completed."
