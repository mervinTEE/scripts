#!/bin/bash
# Usage:
#   WMH_MNI.sh [--robust] <MNI_TEMPLATE> <VENT_BIN> <OUTPUT_ROOT> <SUBJ1> [<SUBJ2> ...]
#
# Example:
#   bash WMH_MNI.sh --robust /path/MNI152_T1_1mm_brain.nii.gz /path/vent_bin.nii.gz \
#       /mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP sub-HD001 sub-HD002

set -euo pipefail

ROBUST=false
if [[ $1 == "--robust" ]]; then
    ROBUST=true
    shift
fi

MNI_TEMPLATE=$1
VENT_BIN=$2
OUTPUT_ROOT=$3
shift 3
SUBJECTS=("$@")

TP_DIRS=("BL" "Y2" "Y4Y5")
OVERALL_LOG="${OUTPUT_ROOT}/pipeline_overall.log"
mkdir -p "$(dirname "$OVERALL_LOG")"
mkdir -p "${OUTPUT_ROOT}/tmp"

echo "========== WMH MNI Pipeline Started $(date) ==========" | tee -a "$OVERALL_LOG"
echo "ROBUST mode = $ROBUST" | tee -a "$OVERALL_LOG"

QC_SCRIPT="/home/admin/Desktop/MRIapp/scripts/WMH/WMH_QC.py"

# -----------------------------
# Loop subjects
# -----------------------------
for SUBJ in "${SUBJECTS[@]}"; do
    echo ">>> Processing $SUBJ" | tee -a "$OVERALL_LOG"
    
    # -------------------------
    # Step 0: Build T1_common
    # -------------------------
    echo "Building T1_common for $SUBJ ..." | tee -a "$OVERALL_LOG"
    T1_LIST=()
    for TP in "${TP_DIRS[@]}"; do
        if [[ "$TP" == "Y4Y5" ]]; then
            TP_PATH="/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Cross_sectional/LSTAI_${TP}/temp/${SUBJ}"
        else
            TP_PATH="/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Cross_sectional/LSTAI_${TP}/${SUBJ}/temp"
        fi
        T1_CAND="${TP_PATH}/sub-X_ses-Y_space-t1w_T1w.nii.gz"
        if [[ -f "$T1_CAND" ]]; then
            T1_LIST+=("$T1_CAND")
        fi
    done
    
    if [ "${#T1_LIST[@]}" -eq 0 ]; then
        echo "No T1 found for $SUBJ, skipping." | tee -a "$OVERALL_LOG"
        continue
    fi
    
    T1_COMMON="${OUTPUT_ROOT}/common/${SUBJ}_T1_common.nii.gz"
    mkdir -p "$(dirname "$T1_COMMON")"
    cp "${T1_LIST[0]}" "$T1_COMMON"
    for ((i=1; i<${#T1_LIST[@]}; i++)); do
        flirt -in "${T1_LIST[$i]}" -ref "$T1_COMMON" \
        -omat "${OUTPUT_ROOT}/tmp/${SUBJ}_to_common_$i.mat" \
        -out "${OUTPUT_ROOT}/tmp/${SUBJ}_to_common_$i.nii.gz" -dof 6
        fslmaths "$T1_COMMON" -add "${OUTPUT_ROOT}/tmp/${SUBJ}_to_common_$i.nii.gz" -div 2 "$T1_COMMON"
    done
    
    # -------------------------
    # Process each TP
    # -------------------------
    echo "Processing PATH for TPs of $SUBJ ..." | tee -a "$OVERALL_LOG"
    for TP in "${TP_DIRS[@]}"; do
        if [[ "$TP" == "Y4Y5" ]]; then
            TP_PATH="/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Cross_sectional/LSTAI_${TP}/temp/${SUBJ}"
        else
            TP_PATH="/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Cross_sectional/LSTAI_${TP}/${SUBJ}/temp"
        fi
        
        T1_NATIVE="${TP_PATH}/sub-X_ses-Y_space-t1w_T1w.nii.gz"
        FLAIR_NATIVE="${TP_PATH}/sub-X_ses-Y_space-flair_FLAIR.nii.gz"
        WMH_NATIVE="${TP_PATH}/sub-X_ses-Y_space-flair_seg-lst.nii.gz"
        if [[ "$TP" != "BL" ]]; then
            WMH_NATIVE="${TP_PATH}/sub-X_ses-Y_space-flair_seg-lst_edited.nii.gz"
        fi
        
        if [[ ! -f "$T1_NATIVE" || ! -f "$FLAIR_NATIVE" || ! -f "$WMH_NATIVE" ]]; then
            echo "Skipping $SUBJ $TP (missing files)" | tee -a "$OVERALL_LOG"
            continue
        fi
        
        OUT_DIR="${OUTPUT_ROOT}/${TP}/${SUBJ}"
        mkdir -p "$OUT_DIR"
        LOG_FILE="${OUT_DIR}/${SUBJ}_${TP}.log"
        
        {
            echo "========== Processing $SUBJ TP=$TP =========="
            
            # -------------------------
            # Step 1: FLAIR → T1
            # -------------------------
            echo "Step 1: FLAIR→T1 registration..." | tee -a "$OVERALL_LOG"
            FLAIR_TO_T1="$OUT_DIR/FLAIR_inT1.nii.gz"
            FLAIR_TO_T1_MAT="$OUT_DIR/FLAIR_to_T1.mat"
            if $ROBUST; then
                flirt -in "$FLAIR_NATIVE" -ref "$T1_NATIVE" -omat "$FLAIR_TO_T1_MAT" \
                -dof 6 -cost corratio -out "$FLAIR_TO_T1"
                mean_val=$(fslstats "$FLAIR_TO_T1" -M || echo 0)
                if (( $(echo "$mean_val < 5" | bc -l) )); then
                    flirt -in "$FLAIR_NATIVE" -ref "$T1_NATIVE" -omat "$FLAIR_TO_T1_MAT" \
                    -dof 12 -cost mutualinfo \
                    -searchrx -90 90 -searchry -90 90 -searchrz -90 90 \
                    -out "$FLAIR_TO_T1"
                fi
            else
                flirt -in "$FLAIR_NATIVE" -ref "$T1_NATIVE" -omat "$FLAIR_TO_T1_MAT" \
                -dof 6 -out "$FLAIR_TO_T1"
            fi
            
            WMH_IN_T1="$OUT_DIR/WMH_inT1.nii.gz"
            flirt -in "$WMH_NATIVE" -ref "$T1_NATIVE" -applyxfm -init "$FLAIR_TO_T1_MAT" \
            -out "$WMH_IN_T1" -interp nearestneighbour
            
            # -------------------------
            # Step 2: T1 → common
            # -------------------------
            echo "Step 2: T1→T1_common registration..." | tee -a "$OVERALL_LOG"
            T1_TO_COMMON_MAT="$OUT_DIR/T1_to_common.mat"
            T1_IN_COMMON="$OUT_DIR/T1_inCommon.nii.gz"
            flirt -in "$T1_NATIVE" -ref "$T1_COMMON" -omat "$T1_TO_COMMON_MAT" \
            -dof 12 -out "$T1_IN_COMMON"
            
            FLAIR_IN_COMMON="$OUT_DIR/FLAIR_inCommon.nii.gz"
            flirt -in "$FLAIR_TO_T1" -ref "$T1_COMMON" -applyxfm -init "$T1_TO_COMMON_MAT" \
            -out "$FLAIR_IN_COMMON" -interp trilinear
            
            WMH_IN_COMMON="$OUT_DIR/WMH_inCommon.nii.gz"
            flirt -in "$WMH_IN_T1" -ref "$T1_COMMON" -applyxfm -init "$T1_TO_COMMON_MAT" \
            -out "$WMH_IN_COMMON" -interp nearestneighbour
            
            # -------------------------
            # Step 3: T1_common → MNI
            # -------------------------
            echo "Step 3: T1_common→MNI registration..." | tee -a "$OVERALL_LOG"
            COMMON_TO_MNI_MAT="$OUT_DIR/common_to_MNI.mat"
            T1_IN_MNI="$OUT_DIR/T1_inMNI.nii.gz"
            flirt -in "$T1_COMMON" -ref "$MNI_TEMPLATE" -omat "$COMMON_TO_MNI_MAT" \
            -dof 12 -out "$T1_IN_MNI"
            
            FLAIR_IN_MNI="$OUT_DIR/FLAIR_common_inMNI.nii.gz"
            flirt -in "$FLAIR_IN_COMMON" -ref "$MNI_TEMPLATE" \
            -applyxfm -init "$COMMON_TO_MNI_MAT" -out "$FLAIR_IN_MNI" -interp trilinear
            
            WMH_IN_MNI="$OUT_DIR/WMH_common_inMNI.nii.gz"
            flirt -in "$WMH_IN_COMMON" -ref "$MNI_TEMPLATE" \
            -applyxfm -init "$COMMON_TO_MNI_MAT" -out "$WMH_IN_MNI" -interp nearestneighbour
            fslmaths "$WMH_IN_MNI" -bin "$OUT_DIR/WMH_common_inMNI_bin.nii.gz"
            
            # -------------------------
            # Step 4: QC
            # -------------------------
            echo "Step 4: Quality Control, printing jpeg..." | tee -a "$OVERALL_LOG"
            if [[ -f "$QC_SCRIPT" ]]; then
                python3 "$QC_SCRIPT" "$OUTPUT_ROOT" "$SUBJ"
            fi
            
            echo "✅ Finished $SUBJ TP=$TP"
        } | tee "$LOG_FILE"
    done
done

echo "========== WMH MNI Pipeline Finished $(date) ==========" | tee -a "$OVERALL_LOG"
