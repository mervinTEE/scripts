#!/bin/bash
# Script to split WMH masks into PVWMH and DWMH for multiple subjects and timepoints
# and generate QC JPEGs automatically per TP.
#
# Usage: WMH_PVDW_multiTP.sh <VENT_BIN> <BASE_DIR> <SUBJ1> [<SUBJ2> ...]
# Example:
# bash WMH_PVDW_multiTP.sh /path/to/vent_bin.nii.gz /mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP sub-HD001 sub-HD002

set -euo pipefail

VENT_BIN="$1"
BASE_PATH="$2"
shift 2
SUBJECTS=("$@")

TP_DIRS=("BL" "Y2" "Y4Y5")
LOG_DIR="${BASE_PATH}/logs"
mkdir -p "$LOG_DIR"
OVERALL_LOG="${LOG_DIR}/DWPV_overall.log"

echo "========== DWPV WMH Pipeline Started $(date) ==========" | tee "$OVERALL_LOG"

for SUBJ in "${SUBJECTS[@]}"; do
    LOG_FILE="${LOG_DIR}/${SUBJ}_DWPV.log"
    {
        echo "===================="
        echo "Processing subject: $SUBJ"
        echo "===================="
    } | tee -a "$OVERALL_LOG" > "$LOG_FILE"
    
    for TP in "${TP_DIRS[@]}"; do
        SUBJ_TP_DIR="${BASE_PATH}/${TP}/${SUBJ}"
        {
            echo "--- Processing TP: $TP ---"
            echo "Subject TP directory: $SUBJ_TP_DIR"
        } | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
        
        if [[ ! -d "$SUBJ_TP_DIR" ]]; then
            echo "TP directory does not exist: $SUBJ_TP_DIR. Skipping this TP." | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
            continue
        fi
        
        # Detect WMH mask
        WMH_MASK=""
        if [[ -f "${SUBJ_TP_DIR}/WMH_common_inMNI_bin.nii.gz" ]]; then
            WMH_MASK="${SUBJ_TP_DIR}/WMH_common_inMNI_bin.nii.gz"
            elif [[ -f "${SUBJ_TP_DIR}/WMH_common_inMNI.nii.gz" ]]; then
            WMH_MASK="${SUBJ_TP_DIR}/WMH_common_inMNI.nii.gz"
        fi
        
        if [[ -z "$WMH_MASK" ]]; then
            echo "No WMH mask found for $SUBJ TP $TP. Skipping this TP." | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
            continue
        else
            echo "WMH mask found: $WMH_MASK" | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
        fi
        
        OUTPUT_DIR="${SUBJ_TP_DIR}/DWPV_output"
        mkdir -p "$OUTPUT_DIR"
        
        echo "Step 1: Binarize WMH mask..." | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
        WMH_BIN="${OUTPUT_DIR}/WMH_bin.nii.gz"
        fslmaths "$WMH_MASK" -bin "$WMH_BIN"
        
        echo "Step 2: Create PV region (10 mm from ventricles)..." | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
        PV_INIT="${OUTPUT_DIR}/PV_region_init.nii.gz"
        fslmaths "$VENT_BIN" -dilM -dilM -dilM -dilM -dilM -dilM -dilM -dilM -dilM -dilM "$PV_INIT"
        
        echo "Step 3: Initial PVWMH mask..." | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
        PVWMH_INIT="${OUTPUT_DIR}/PVWMH_init.nii.gz"
        fslmaths "$WMH_BIN" -mas "$PV_INIT" "$PVWMH_INIT"
        
        echo "Step 4: Iterative PVWMH growth..." | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
        PVWMH_GROW="${OUTPUT_DIR}/PVWMH.nii.gz"
        cp "$PVWMH_INIT" "$PVWMH_GROW"
        
        changed=1
        iter=1
        while [[ $changed -eq 1 ]]; do
            TMP_GROW="${OUTPUT_DIR}/PVWMH_tmp.nii.gz"
            fslmaths "$PVWMH_GROW" -dilM "$TMP_GROW"
            fslmaths "$TMP_GROW" -mas "$WMH_BIN" "$TMP_GROW"
            fslmaths "$PVWMH_GROW" -add "$TMP_GROW" -bin "$TMP_GROW"
            
            old_vox=$(fslstats "$PVWMH_GROW" -V | awk '{print $1}')
            new_vox=$(fslstats "$TMP_GROW" -V | awk '{print $1}')
            
            if [[ "$new_vox" -eq "$old_vox" ]]; then
                changed=0
                echo "Iteration $iter: No new voxels added. Stopping." | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
            else
                mv "$TMP_GROW" "$PVWMH_GROW"
                ((iter++))
                echo "Iteration $iter: PVWMH grown to $new_vox voxels." | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
            fi
        done
        
        echo "Step 5: Define DWMH..." | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
        DWMH="${OUTPUT_DIR}/DWMH.nii.gz"
        fslmaths "$WMH_BIN" -sub "$PVWMH_GROW" -bin "$DWMH"
        
        echo "✅ TP $TP complete. PVWMH: $PVWMH_GROW, DWMH: $DWMH" | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
        
        # -----------------------------
        # Run lightweight QC script
        # -----------------------------
        echo "Running QC montage for $SUBJ $TP..." | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
        python3 /home/admin/Desktop/MRIapp/scripts/WMH/DWPV_QC.py "$BASE_PATH" "$SUBJ" || {
            echo "⚠️ QC generation failed for $SUBJ $TP" | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
        }
        
        echo "-----------------------------" | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
    done
    
    echo "All TPs processed for $SUBJ" | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
done

echo "========== DWPV WMH Pipeline Finished $(date) ==========" | tee -a "$OVERALL_LOG"
