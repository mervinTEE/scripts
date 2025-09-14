#!/bin/bash
# Usage: WMH_MNI.sh <MNI_TEMPLATE> <VENT_BIN> <OUTPUT_ROOT> <SUBJ1> [<SUBJ2> ...]
# Example:
# bash WMH_MNI.sh /path/to/MNI152_T1_1mm_brain.nii.gz /path/to/vent_bin.nii.gz /mnt/hdd/MT/HARMY/Longitudinal_Output sub-HD001 sub-HD002

set -euo pipefail

MNI_TEMPLATE=$1
VENT_BIN=$2
OUTPUT_ROOT=$3
shift 3
SUBJECTS=("$@")

TP_DIRS=("BL" "Y2" "Y4Y5")
OVERALL_LOG="${OUTPUT_ROOT}/pipeline_overall.log"
mkdir -p "$(dirname "$OVERALL_LOG")"

echo "========== WMH MNI Pipeline Started $(date) ==========" | tee -a "$OVERALL_LOG"

for SUBJ in "${SUBJECTS[@]}"; do
    echo "Processing $SUBJ ..." | tee -a "$OVERALL_LOG"
    
    # -------------------------
    # Define cross-sectional files
    # -------------------------
    TP_T1=(
        "/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Cross_sectional/LSTAI_BL/${SUBJ}/temp/sub-X_ses-Y_space-t1w_T1w.nii.gz"
        "/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Cross_sectional/LSTAI_Y2/${SUBJ}/temp/sub-X_ses-Y_space-t1w_T1w.nii.gz"
        "/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Cross_sectional/LSTAI_Y4Y5/temp/${SUBJ}/sub-X_ses-Y_space-t1w_T1w.nii.gz"
    )
    TP_FLAIR=(
        "/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Cross_sectional/LSTAI_BL/${SUBJ}/temp/sub-X_ses-Y_space-flair_FLAIR.nii.gz"
        "/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Cross_sectional/LSTAI_Y2/${SUBJ}/temp/sub-X_ses-Y_space-flair_FLAIR.nii.gz"
        "/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Cross_sectional/LSTAI_Y4Y5/temp/${SUBJ}/sub-X_ses-Y_space-flair_FLAIR.nii.gz"
    )
    TP_WMH=(
        "/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Cross_sectional/LSTAI_BL/${SUBJ}/temp/sub-X_ses-Y_space-flair_seg-lst.nii.gz"
        "/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Cross_sectional/LSTAI_Y2/${SUBJ}/temp/sub-X_ses-Y_space-flair_seg-lst_edited.nii.gz"
        "/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Cross_sectional/LSTAI_Y4Y5/temp/${SUBJ}/sub-X_ses-Y_space-flair_seg-lst_edited.nii.gz"
    )
    
    # -------------------------
    # Identify existing TPs
    # -------------------------
    EXISTING_TP=()
    for i in 0 1 2; do
        if [[ -f "${TP_T1[$i]}" ]]; then
            EXISTING_TP+=("$i")
        else
            echo "TP ${TP_DIRS[$i]} missing T1 for $SUBJ, skipping this TP." | tee -a "$OVERALL_LOG"
        fi
    done
    
    if [ "${#EXISTING_TP[@]}" -eq 0 ]; then
        echo "No T1 images found for $SUBJ, skipping subject." | tee -a "$OVERALL_LOG"
        continue
    fi
    
    # -------------------------
    # Generate T1_COMMON
    # -------------------------
    T1_COMMON="${OUTPUT_ROOT}/common/${SUBJ}_T1_common.nii.gz"
    mkdir -p "$(dirname "$T1_COMMON")"
    mkdir -p "${OUTPUT_ROOT}/tmp"
    
    FIRST_TP=${EXISTING_TP[0]}
    cp "${TP_T1[$FIRST_TP]}" "$T1_COMMON"
    ID_MATRIX="${OUTPUT_ROOT}/tmp/${SUBJ}_T1_TP${FIRST_TP}_to_common.mat"
    echo -e "1 0 0 0\n0 1 0 0\n0 0 1 0\n0 0 0 1" > "$ID_MATRIX"
    
    # Register remaining TPs to T1_COMMON
    if [ "${#EXISTING_TP[@]}" -gt 1 ]; then
        for i in "${EXISTING_TP[@]}"; do
            if [ "$i" -eq "$FIRST_TP" ]; then
                continue
            fi
            OUTMAT="${OUTPUT_ROOT}/tmp/${SUBJ}_T1_TP${i}_to_common.mat"
            OUTIMG="${OUTPUT_ROOT}/tmp/${SUBJ}_T1_TP${i}_to_common.nii.gz"
            flirt -in "${TP_T1[$i]}" -ref "$T1_COMMON" -out "$OUTIMG" -omat "$OUTMAT" -dof 6
            # Add to average
            fslmaths "$T1_COMMON" -add "$OUTIMG" -div 2 "$T1_COMMON"
        done
    fi
    
    # -------------------------
    # Process each existing TP
    # -------------------------
    for i in 0 1 2; do
        if [[ ! " ${EXISTING_TP[*]} " =~ " $i " ]]; then
            echo "Skipping TP ${TP_DIRS[$i]} for $SUBJ (missing files)." | tee -a "$OVERALL_LOG"
            continue
        fi
        
        OUT_DIR="${OUTPUT_ROOT}/${TP_DIRS[$i]}/${SUBJ}"
        mkdir -p "$OUT_DIR"
        LOG_FILE="${OUT_DIR}/${SUBJ}_${TP_DIRS[$i]}.log"
        
        {
            echo "========== Processing ${SUBJ}, TP=${TP_DIRS[$i]} =========="
            
            FLAIR_NATIVE="${TP_FLAIR[$i]}"
            T1_NATIVE="${TP_T1[$i]}"
            WMH_IN="${TP_WMH[$i]}"
            WMH_B=$(basename "$WMH_IN")
            
            # Check files exist
            if [[ ! -f "$FLAIR_NATIVE" ]]; then
                echo "FLAIR missing for TP ${TP_DIRS[$i]}, skipping TP."
                continue
            fi
            if [[ ! -f "$WMH_IN" ]]; then
                echo "WMH missing for TP ${TP_DIRS[$i]}, skipping TP."
                continue
            fi
            
            # Step 1: FLAIR → T1-native → T1-common
            FLAIR_TO_T1="$OUT_DIR/FLAIR_to_T1.nii.gz"
            FLAIR_TO_T1_MAT="$OUT_DIR/FLAIR_to_T1.mat"
            FLAIR_TO_COMMON="$OUT_DIR/FLAIR_to_common.nii.gz"
            
            flirt -in "$FLAIR_NATIVE" -ref "$T1_NATIVE" -out "$FLAIR_TO_T1" -omat "$FLAIR_TO_T1_MAT" -dof 6
            
            T1MAT="${OUTPUT_ROOT}/tmp/${SUBJ}_T1_TP${i}_to_common.mat"
            if [[ "$i" -eq "$FIRST_TP" ]]; then
                if [[ "$ID_MATRIX" != "$T1MAT" ]]; then
                    cp "$ID_MATRIX" "$T1MAT"
                fi
            fi
            
            flirt -in "$FLAIR_TO_T1" -ref "$T1_COMMON" -applyxfm -init "$T1MAT" -out "$FLAIR_TO_COMMON" -interp trilinear
            
            # Step 2: FLAIR_common → MNI
            FLAIR_COMMON_TO_MNI="$OUT_DIR/FLAIR_common_to_MNI.mat"
            FLAIR_COMMON_IN_MNI="$OUT_DIR/FLAIR_common_in_MNI.nii.gz"
            flirt -in "$FLAIR_TO_COMMON" -ref "$MNI_TEMPLATE" -omat "$FLAIR_COMMON_TO_MNI" -dof 12
            flirt -in "$FLAIR_TO_COMMON" -ref "$MNI_TEMPLATE" -applyxfm -init "$FLAIR_COMMON_TO_MNI" -out "$FLAIR_COMMON_IN_MNI" -interp trilinear
            
            # Step 3: WMH → FLAIR → T1-native → T1-common → MNI
            WMH_IN_FLAIR="$OUT_DIR/${WMH_B%.nii.gz}_inFLAIR.nii.gz"
            WMH_IN_T1="$OUT_DIR/${WMH_B%.nii.gz}_inT1.nii.gz"
            WMH_TO_COMMON="$OUT_DIR/${WMH_B%.nii.gz}_to_common.nii.gz"
            WMH_IN_MNI="$OUT_DIR/${WMH_B%.nii.gz}_in_MNI.nii.gz"
            
            flirt -in "$WMH_IN" -ref "$FLAIR_NATIVE" -out "$WMH_IN_FLAIR" -interp nearestneighbour
            flirt -in "$WMH_IN_FLAIR" -ref "$T1_NATIVE" -applyxfm -init "$FLAIR_TO_T1_MAT" -out "$WMH_IN_T1" -interp nearestneighbour
            flirt -in "$WMH_IN_T1" -ref "$T1_COMMON" -applyxfm -init "$T1MAT" -out "$WMH_TO_COMMON" -interp nearestneighbour
            flirt -in "$WMH_TO_COMMON" -ref "$MNI_TEMPLATE" -applyxfm -init "$FLAIR_COMMON_TO_MNI" -out "$WMH_IN_MNI" -interp nearestneighbour
            fslmaths "$WMH_IN_MNI" -bin "$OUT_DIR/${WMH_B%.nii.gz}_in_MNI_bin.nii.gz"
            
            echo "✅ Finished ${SUBJ}, TP=${TP_DIRS[$i]}"
        } | tee "$LOG_FILE"
    done
    
    echo "$SUBJ complete. Outputs per TP in: $OUTPUT_ROOT/<TP>/${SUBJ}/" | tee -a "$OVERALL_LOG"
done

echo "========== WMH MNI Pipeline Finished $(date) ==========" | tee -a "$OVERALL_LOG"
