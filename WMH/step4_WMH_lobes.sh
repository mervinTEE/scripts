#!/bin/bash
# WMH_brainlobe.sh
# Script to extract WMH overlap volumes by brain lobes
# Includes left, right, and combined (LR) lobes
#
# Usage: WMH_brainlobe.sh <ATLAS> <BASE_DIR> <SUBJ1> [<SUBJ2> ...]

set -euo pipefail

ATLAS="$1"
BASE_PATH="$2"
shift 2
SUBJECTS=("$@")

# Atlas labels of interest
declare -A LOBES=(
    [1]="Right_Frontal"
    [2]="Right_Parietal"
    [3]="Right_Occipital"
    [4]="Right_Temporal"
    [5]="Right_IF_Cerebellum"
    [11]="Left_Frontal"
    [12]="Left_Parietal"
    [13]="Left_Occipital"
    [14]="Left_Temporal"
    [15]="Left_IF"
)

# Define combined pairs (R+L → LR)
declare -A COMBINED_LOBES=(
    ["Frontal"]="1,11"
    ["Parietal"]="2,12"
    ["Occipital"]="3,13"
    ["Temporal"]="4,14"
    ["IF_Cerebellum"]="5,15"
)

TP_DIRS=("BL" "Y2" "Y4Y5")
LOG_DIR="${BASE_PATH}/logs"
mkdir -p "$LOG_DIR"
OVERALL_LOG="${LOG_DIR}/WMH_brainlobe_overall.log"



for SUBJ in "${SUBJECTS[@]}"; do
    echo "========== WMH Brain Lobe Extraction Started for ${SUBJ} $(date) ==========" | tee "$OVERALL_LOG"
    LOG_FILE="${LOG_DIR}/${SUBJ}_WMH_brainlobe.log"
    {
        echo "===================="
        echo "Processing subject: $SUBJ"
        echo "===================="
    } | tee -a "$OVERALL_LOG" > "$LOG_FILE"
    
    for TP in "${TP_DIRS[@]}"; do
        SUBJ_TP_DIR="${BASE_PATH}/${TP}/${SUBJ}"
        WMH_MASK="${SUBJ_TP_DIR}/WMH_common_inMNI_bin.nii.gz"
        
        if [[ ! -f "$WMH_MASK" ]]; then
            echo "No WMH mask for $SUBJ $TP, skipping." | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
            continue
        fi
        
        OUTPUT_DIR="${SUBJ_TP_DIR}/Brain_lobes_outputs"
        mkdir -p "$OUTPUT_DIR"
        
        echo "--- $SUBJ $TP ---" | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
        
        COUNT_FILE="${OUTPUT_DIR}/WMH_lobe_counts.txt"
        echo -e "SUBJ\tTP\tLABEL\tNAME\tVoxels\tVolume_mm3" > "$COUNT_FILE"
        
        # --- Individual lobes ---
        for LABEL in "${!LOBES[@]}"; do
            NAME="${LOBES[$LABEL]}"
            LOBE_MASK="${OUTPUT_DIR}/WMH_${NAME}.nii.gz"
            
            # Extract lobe from atlas
            fslmaths "$ATLAS" -thr "$LABEL" -uthr "$LABEL" -bin "${OUTPUT_DIR}/tmp_lobe.nii.gz"
            
            # Intersect with WMH
            fslmaths "$WMH_MASK" -mas "${OUTPUT_DIR}/tmp_lobe.nii.gz" "$LOBE_MASK"
            
            # Get voxel count
            vox=$(fslstats "$LOBE_MASK" -V | awk '{print $1}')
            mm3=$(fslstats "$LOBE_MASK" -V | awk '{print $2}')
            echo -e "$SUBJ\t$TP\t$LABEL\t$NAME\t$vox\t$mm3" >> "$COUNT_FILE"
            
            echo "   $NAME: $vox voxels ($mm3 mm^3)" | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
        done
        
        # --- Combined LR lobes ---
        for COMB in "${!COMBINED_LOBES[@]}"; do
            LABELS="${COMBINED_LOBES[$COMB]}"
            COMB_MASK="${OUTPUT_DIR}/WMH_${COMB}_LR.nii.gz"
            
            # Extract both hemispheres, combine
            fslmaths "$ATLAS" -thr $(echo $LABELS | cut -d',' -f1) -uthr $(echo $LABELS | cut -d',' -f1) -bin "${OUTPUT_DIR}/tmp1.nii.gz"
            fslmaths "$ATLAS" -thr $(echo $LABELS | cut -d',' -f2) -uthr $(echo $LABELS | cut -d',' -f2) -bin "${OUTPUT_DIR}/tmp2.nii.gz"
            fslmaths "${OUTPUT_DIR}/tmp1.nii.gz" -add "${OUTPUT_DIR}/tmp2.nii.gz" -bin "${OUTPUT_DIR}/tmp_lobe.nii.gz"
            
            # Intersect with WMH
            fslmaths "$WMH_MASK" -mas "${OUTPUT_DIR}/tmp_lobe.nii.gz" "$COMB_MASK"
            
            # Get voxel count
            vox=$(fslstats "$COMB_MASK" -V | awk '{print $1}')
            mm3=$(fslstats "$COMB_MASK" -V | awk '{print $2}')
            echo -e "$SUBJ\t$TP\tNA\t${COMB}_LR\t$vox\t$mm3" >> "$COUNT_FILE"
            
            echo "   ${COMB}_LR: $vox voxels ($mm3 mm^3)" | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
        done
        
        rm -f "${OUTPUT_DIR}/tmp1.nii.gz" "${OUTPUT_DIR}/tmp2.nii.gz" "${OUTPUT_DIR}/tmp_lobe.nii.gz"
    done
    
    echo "All TPs processed for $SUBJ" | tee -a "$OVERALL_LOG" >> "$LOG_FILE"
done

echo "========== WMH Brain Lobe Extraction Finished $(date) ==========" | tee -a "$OVERALL_LOG"
