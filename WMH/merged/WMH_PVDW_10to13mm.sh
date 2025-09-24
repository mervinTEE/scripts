#!/bin/bash
# Script to split WMH masks into PVWMH and DWMH based on distance thresholds (10mm, 13mm)
#
# Usage: WMH_PVDW_distance.sh <VENT_BIN> <BASE_DIR> <SUBJ1> [<SUBJ2> ...]
# Example:
# bash WMH_PVDW_distance.sh /path/to/vent_bin.nii.gz /mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP sub-HD001 sub-HD002

set -euo pipefail

VENT_BIN="$1"
BASE_PATH="$2"
shift 2
SUBJECTS=("$@")

TP_DIRS=("BL" "Y2" "Y4Y5")
LOG_DIR="${BASE_PATH}/logs"
mkdir -p "$LOG_DIR"
OVERALL_LOG="${LOG_DIR}/DWPV_dist_overall.log"

echo "========== DWPV Distance-based WMH Pipeline Started $(date) ==========" | tee "$OVERALL_LOG"

for SUBJ in "${SUBJECTS[@]}"; do
    LOG_FILE="${LOG_DIR}/${SUBJ}_DWPV_dist.log"
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
        if [[ -f "${SUBJ_TP_DIR}/WMH_common_inMNI_binfinal.nii.gz" ]]; then
            WMH_MASK="${SUBJ_TP_DIR}/WMH_common_inMNI_binfinal.nii.gz"
            elif [[ -f "${SUBJ_TP_DIR}/WMH_common_inMNI.nii.gz" ]]; then
            WMH_MASK="${SUBJ_TP_DIR}/WMH_common_inMNI.nii.gz"
        fi
        
        if [[ -z "$WMH_MASK" ]]; then
            echo "No WMH mask found for $SUBJ TP $TP. Skipping this TP." | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
            continue
        else
            echo "WMH mask found: $WMH_MASK" | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
        fi
        
        OUTPUT_DIR="${SUBJ_TP_DIR}/DWPV_dist_output"
        mkdir -p "$OUTPUT_DIR"
        
        echo "Step 1: Binarize WMH mask..." | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
        WMH_BIN="${OUTPUT_DIR}/WMH_bin.nii.gz"
        fslmaths "$WMH_MASK" -bin "$WMH_BIN"
        
        # -------- Distance-based PV/DW with 10 mm --------
        echo "Step 2a: Create 10-mm PV zone..." | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
        PV_ZONE10="${OUTPUT_DIR}/PV_zone10.nii.gz"
        fslmaths "$VENT_BIN" -dilM -dilM -dilM -dilM -dilM -dilM -dilM -dilM -dilM -dilM "$PV_ZONE10"
        
        echo "Step 3a: PVWMH (10 mm)..." | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
        PVWMH10="${OUTPUT_DIR}/PVWMH_10mm.nii.gz"
        fslmaths "$WMH_BIN" -mas "$PV_ZONE10" "$PVWMH10"
        
        echo "Step 4a: DWMH (10 mm)..." | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
        DWMH10="${OUTPUT_DIR}/DWMH_10mm.nii.gz"
        fslmaths "$WMH_BIN" -sub "$PVWMH10" -bin "$DWMH10"
        
        # -------- Distance-based PV/DW with 13 mm --------
        echo "Step 2b: Create 13-mm PV zone..." | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
        PV_ZONE13="${OUTPUT_DIR}/PV_zone13.nii.gz"
        fslmaths "$VENT_BIN" -dilM -dilM -dilM -dilM -dilM -dilM -dilM -dilM -dilM -dilM -dilM -dilM -dilM "$PV_ZONE13"
        
        echo "Step 3b: PVWMH (13 mm)..." | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
        PVWMH13="${OUTPUT_DIR}/PVWMH_13mm.nii.gz"
        fslmaths "$WMH_BIN" -mas "$PV_ZONE13" "$PVWMH13"
        
        echo "Step 4b: DWMH (13 mm)..." | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
        DWMH13="${OUTPUT_DIR}/DWMH_13mm.nii.gz"
        fslmaths "$WMH_BIN" -sub "$PVWMH13" -bin "$DWMH13"
        
        echo "✅ TP $TP complete. Outputs saved in $OUTPUT_DIR" | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
        
        echo "-----------------------------" | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
    done
    
    echo "All TPs processed for $SUBJ" | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
done

echo "========== DWPV Distance-based WMH Pipeline Finished $(date) ==========" | tee -a "$OVERALL_LOG"
