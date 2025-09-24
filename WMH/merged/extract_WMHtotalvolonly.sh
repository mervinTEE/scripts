#!/bin/bash
# WMH_extract_volumes.sh
# Extract WMH, PVWMH, DWMH, distance-based PV/DW, and lobe-wise volumes
# Outputs subject-wise CSV table with volumes in mm3 and ml
#
# Usage:
# bash WMH_extract_volumes.sh <BASE_DIR> <OUTPUT_CSV> <SUBJ1> [<SUBJ2> ...]

set -euo pipefail

BASE_PATH="$1"
OUT_CSV="$2"
shift 2
SUBJECTS=("$@")

TP_DIRS=("BL" "Y2" "Y4Y5")

# CSV header
HEADER="Subject,TP,WMH_mm3,WMH_ml,PVWMH_mm3,PVWMH_ml,DWMH_mm3,DWMH_ml,PVWMH_10mm_mm3,PVWMH_10mm_ml,DWMH_10mm_mm3,DWMH_10mm_ml,PVWMH_13mm_mm3,PVWMH_13mm_ml,DWMH_13mm_mm3,DWMH_13mm_ml"
HEADER="$HEADER,Left_Frontal_mm3,Left_Frontal_ml,Left_Temporal_mm3,Left_Temporal_ml,Left_Parietal_mm3,Left_Parietal_ml,Left_Occipital_mm3,Left_Occipital_ml,Left_IF_mm3,Left_IF_ml"
HEADER="$HEADER,Right_Frontal_mm3,Right_Frontal_ml,Right_Temporal_mm3,Right_Temporal_ml,Right_Parietal_mm3,Right_Parietal_ml,Right_Occipital_mm3,Right_Occipital_ml,Right_IF_Cerebellum_mm3,Right_IF_Cerebellum_ml"
HEADER="$HEADER,B_Frontal_mm3,B_Frontal_ml,B_Temporal_mm3,B_Temporal_ml,B_Parietal_mm3,B_Parietal_ml,B_Occipital_mm3,B_Occipital_ml,B_IF_Cerebellum_mm3,B_IF_Cerebellum_ml"

echo "$HEADER" > "$OUT_CSV"

# Function to get volume in mm3 and ml
get_volumes() {
    local file=$1
    if [[ -f "$file" ]]; then
        vals=$(fslstats "$file" -V)
        mm3=$(echo $vals | awk '{print $2}')
        ml=$(echo "scale=4; $mm3/1000" | bc)
        echo "$mm3,$ml"
    else
        echo "NA,NA"
    fi
}

for SUBJ in "${SUBJECTS[@]}"; do
    for TP in "${TP_DIRS[@]}"; do
        SUBJ_TP_DIR="${BASE_PATH}/${TP}/${SUBJ}"
        if [[ ! -d "$SUBJ_TP_DIR" ]]; then
            continue
        fi
        
        # Collect ROI volumes
        row="$SUBJ,$TP"
        
        # --- Core masks ---
        row="$row,$(get_volumes ${SUBJ_TP_DIR}/WMH_common_inMNI_binfinal.nii.gz)"
        
        # Append row to CSV
        echo "$row" >> "$OUT_CSV"
    done
done

echo "✅ Volume extraction complete. Results saved to $OUT_CSV"
