#!/bin/bash
#############################################################################################
# WMH_longitudinal_pipeline.sh (with existence checking and logging for each step)
#
# USAGE:
#   bash WMH_longitudinal_pipeline.sh [--robust] <MNI_TEMPLATE> <VENT_BIN> <BRAINLOBE_ATLAS> <OUTPUT_ROOT> <SUBJ1> [<SUBJ2> ...]
#
# Update the paths to python scripts as needed below.
#############################################################################################

set -euo pipefail

# ==== EDIT PATHS TO YOUR PYTHON SCRIPTS IF NEEDED ====
WMH_QC_PY=/home/admin/Desktop/MRIapp/scripts/WMH/WMH_QC.py
DWPV_QC_PY=/home/admin/Desktop/MRIapp/scripts/WMH/DWPV_QC.py
# =====================================================

ROBUST=false
if [[ $1 == "--robust" ]]; then
    ROBUST=true
    shift
fi

if [[ $# -lt 5 ]]; then
    echo "Usage: $0 [--robust] <MNI_TEMPLATE> <VENT_BIN> <BRAINLOBE_ATLAS> <OUTPUT_ROOT> <SUBJ1> [<SUBJ2> ...]"
    exit 1
fi

MNI_TEMPLATE=$1
VENT_BIN=$2
BRAINLOBE_ATLAS=$3
OUTPUT_ROOT=$4
shift 4
SUBJECTS=("$@")
TP_DIRS=("BL" "Y2" "Y4Y5")

LOG="${OUTPUT_ROOT}/longitudinal_pipeline.log"
mkdir -p "$(dirname "$LOG")"
mkdir -p "${OUTPUT_ROOT}/tmp"

echo "========== WMH Combined Pipeline Started $(date) ==========" | tee -a "$LOG"
echo "ROBUST mode = $ROBUST" | tee -a "$LOG"

for SUBJ in "${SUBJECTS[@]}"; do
    echo ">>> Processing $SUBJ" | tee -a "$LOG"

    # ---- STEP 1: T1 COMMON ----
    T1_LIST=()
    for TP in "${TP_DIRS[@]}"; do
        if [[ "$TP" == "Y4Y5" ]]; then
            TP_PATH="${OUTPUT_ROOT}/../../Cross_sectional/LSTAI_${TP}/temp/${SUBJ}"
        else
            TP_PATH="${OUTPUT_ROOT}/../../Cross_sectional/LSTAI_${TP}/${SUBJ}/temp"
        fi
        T1_CAND="${TP_PATH}/sub-X_ses-Y_space-t1w_T1w.nii.gz"
        if [[ -f "$T1_CAND" ]]; then
            T1_LIST+=("$T1_CAND")
        fi
    done

    if [ "${#T1_LIST[@]}" -eq 0 ]; then
        echo "No T1 found for $SUBJ, skipping." | tee -a "$LOG"
        continue
    fi

    T1_COMMON="${OUTPUT_ROOT}/common/${SUBJ}_T1_common.nii.gz"
    if [[ -f "$T1_COMMON" ]]; then
        echo "[exists] $T1_COMMON -- skipping T1_common creation." | tee -a "$LOG"
    else
        mkdir -p "$(dirname "$T1_COMMON")"
        cp "${T1_LIST[0]}" "$T1_COMMON"
        for ((i=1; i<${#T1_LIST[@]}; i++)); do
            OUT_MAT="${OUTPUT_ROOT}/tmp/${SUBJ}_to_common_$i.mat"
            OUT_NII="${OUTPUT_ROOT}/tmp/${SUBJ}_to_common_$i.nii.gz"
            flirt -in "${T1_LIST[$i]}" -ref "$T1_COMMON" -omat "$OUT_MAT" -out "$OUT_NII" -dof 6
            fslmaths "$T1_COMMON" -add "$OUT_NII" -div 2 "$T1_COMMON"
        done
    fi

    # ---- STEP 2: PER TIMEPOINT ----
    for TP in "${TP_DIRS[@]}"; do
        echo ">> Processing $SUBJ $TP ..." | tee -a "$LOG"
        if [[ -d "${OUTPUT_ROOT}/../../Cross_sectional/LSTAI_${TP}/${SUBJ}/temp" ]]; then
        TP_PATH="${OUTPUT_ROOT}/../../Cross_sectional/LSTAI_${TP}/${SUBJ}/temp"
    elif [[ -d "${OUTPUT_ROOT}/../../Cross_sectional/LSTAI_${TP}/temp/${SUBJ}" ]]; then
        TP_PATH="${OUTPUT_ROOT}/../../Cross_sectional/LSTAI_${TP}/temp/${SUBJ}"
    else
        echo "[ERROR] Could not find expected folder for $TP $SUBJ" | tee -a "$LOG"
        continue
    fi

        T1_NATIVE="${TP_PATH}/sub-X_ses-Y_space-t1w_T1w.nii.gz"
        FLAIR_NATIVE="${TP_PATH}/sub-X_ses-Y_space-flair_FLAIR.nii.gz"
        WMH_NATIVE="${TP_PATH}/sub-X_ses-Y_space-flair_seg-lst.nii.gz"
        if [[ "$TP" != "BL" ]]; then
            WMH_NATIVE="${TP_PATH}/sub-X_ses-Y_space-flair_seg-lst_edited.nii.gz"
        fi

        if [[ ! -f "$T1_NATIVE" || ! -f "$FLAIR_NATIVE" || ! -f "$WMH_NATIVE" ]]; then
            echo "Skipping $SUBJ $TP (missing FLAIR/T1/WMH)" | tee -a "$LOG"
            continue
        fi

        OUT_DIR="${OUTPUT_ROOT}/${TP}/${SUBJ}"
        mkdir -p "$OUT_DIR"

        # FLAIR->T1
        FLAIR_TO_T1="$OUT_DIR/FLAIR_inT1.nii.gz"
        FLAIR_TO_T1_MAT="$OUT_DIR/FLAIR_to_T1.mat"
        if [[ -f "$FLAIR_TO_T1" && -f "$FLAIR_TO_T1_MAT" ]]; then
            echo "[exists] $FLAIR_TO_T1 and $FLAIR_TO_T1_MAT -- skipping FLAIR->T1." | tee -a "$LOG"
        else
            if $ROBUST; then
                flirt -in "$FLAIR_NATIVE" -ref "$T1_NATIVE" -omat "$FLAIR_TO_T1_MAT" \
                    -dof 6 -cost corratio -out "$FLAIR_TO_T1"
                mean_val=$(fslstats "$FLAIR_TO_T1" -M || echo 0)
                if (( $(echo "$mean_val < 5" | bc -l) )); then
                    flirt -in "$FLAIR_NATIVE" -ref "$T1_NATIVE" -omat "$FLAIR_TO_T1_MAT" \
                        -dof 12 -cost mutualinfo \
                        -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -out "$FLAIR_TO_T1"
                fi
            else
                flirt -in "$FLAIR_NATIVE" -ref "$T1_NATIVE" -omat "$FLAIR_TO_T1_MAT" -dof 6 -out "$FLAIR_TO_T1"
            fi
        fi

        # WMH->T1
        WMH_IN_T1="$OUT_DIR/WMH_inT1.nii.gz"
        if [[ -f "$WMH_IN_T1" ]]; then
            echo "[exists] $WMH_IN_T1 -- skipping WMH->T1." | tee -a "$LOG"
        else
            flirt -in "$WMH_NATIVE" -ref "$T1_NATIVE" -applyxfm -init "$FLAIR_TO_T1_MAT" \
                -out "$WMH_IN_T1" -interp nearestneighbour
        fi

        # T1->common
        T1_TO_COMMON_MAT="$OUT_DIR/T1_to_common.mat"
        T1_IN_COMMON="$OUT_DIR/T1_inCommon.nii.gz"
        if [[ -f "$T1_IN_COMMON" && -f "$T1_TO_COMMON_MAT" ]]; then
            echo "[exists] $T1_IN_COMMON and $T1_TO_COMMON_MAT -- skipping T1->common." | tee -a "$LOG"
        else
            flirt -in "$T1_NATIVE" -ref "$T1_COMMON" -omat "$T1_TO_COMMON_MAT" \
                -dof 12 -out "$T1_IN_COMMON"
        fi

        FLAIR_IN_COMMON="$OUT_DIR/FLAIR_inCommon.nii.gz"
        if [[ -f "$FLAIR_IN_COMMON" ]]; then
            echo "[exists] $FLAIR_IN_COMMON -- skipping FLAIR->common." | tee -a "$LOG"
        else
            flirt -in "$FLAIR_TO_T1" -ref "$T1_COMMON" -applyxfm -init "$T1_TO_COMMON_MAT" \
                -out "$FLAIR_IN_COMMON" -interp trilinear
        fi

        WMH_IN_COMMON="$OUT_DIR/WMH_inCommon.nii.gz"
        if [[ -f "$WMH_IN_COMMON" ]]; then
            echo "[exists] $WMH_IN_COMMON -- skipping WMH->common." | tee -a "$LOG"
        else
            flirt -in "$WMH_IN_T1" -ref "$T1_COMMON" -applyxfm -init "$T1_TO_COMMON_MAT" \
                -out "$WMH_IN_COMMON" -interp nearestneighbour
        fi

        # T1_common->MNI
        COMMON_TO_MNI_MAT="$OUT_DIR/common_to_MNI.mat"
        T1_IN_MNI="$OUT_DIR/T1_inMNI.nii.gz"
        if [[ -f "$T1_IN_MNI" && -f "$COMMON_TO_MNI_MAT" ]]; then
            echo "[exists] $T1_IN_MNI and $COMMON_TO_MNI_MAT -- skipping common->MNI." | tee -a "$LOG"
        else
            flirt -in "$T1_COMMON" -ref "$MNI_TEMPLATE" -omat "$COMMON_TO_MNI_MAT" -dof 12 -out "$T1_IN_MNI"
        fi

        FLAIR_IN_MNI="$OUT_DIR/FLAIR_common_inMNI.nii.gz"
        if [[ -f "$FLAIR_IN_MNI" ]]; then
            echo "[exists] $FLAIR_IN_MNI -- skipping FLAIR->MNI." | tee -a "$LOG"
        else
            flirt -in "$FLAIR_IN_COMMON" -ref "$MNI_TEMPLATE" -applyxfm -init "$COMMON_TO_MNI_MAT" \
                -out "$FLAIR_IN_MNI" -interp trilinear
        fi

        WMH_IN_MNI="$OUT_DIR/WMH_common_inMNI.nii.gz"
        WMH_IN_MNI_BIN="$OUT_DIR/WMH_common_inMNI_bin.nii.gz"
        if [[ -f "$WMH_IN_MNI" && -f "$WMH_IN_MNI_BIN" ]]; then
            echo "[exists] $WMH_IN_MNI_BIN -- skipping WMH->MNI/bin." | tee -a "$LOG"
        else
            flirt -in "$WMH_IN_COMMON" -ref "$MNI_TEMPLATE" -applyxfm -init "$COMMON_TO_MNI_MAT" \
                -out "$WMH_IN_MNI" -interp nearestneighbour
            fslmaths "$WMH_IN_MNI" -bin "$WMH_IN_MNI_BIN"
        fi

        # QC - WMH
        QC_DIR="${OUT_DIR}/QC_JPEGs"
        QC_FILE="${QC_DIR}/${SUBJ}_${TP}_QC.jpg"
        if [[ -f "$QC_FILE" ]]; then
            echo "[exists] QC: $QC_FILE -- skipping WMH QC." | tee -a "$LOG"
        else
            mkdir -p "$QC_DIR"
            if [[ -f "$WMH_QC_PY" ]]; then
                python3 "$WMH_QC_PY" "$OUTPUT_ROOT" "$SUBJ"
            fi
        fi

        # ---- STEP 3: PV/DW SPLITTING ----
        SUBJ_TP_DIR="${OUTPUT_ROOT}/${TP}/${SUBJ}"
        WMH_MASK="$WMH_IN_MNI_BIN"
        OUTPUT_DIR="${SUBJ_TP_DIR}/DWPV_output"
        PVWMH="${OUTPUT_DIR}/PVWMH.nii.gz"
        DWMH="${OUTPUT_DIR}/DWMH.nii.gz"
        if [[ -f "$PVWMH" && -f "$DWMH" ]]; then
            echo "[exists] $PVWMH and $DWMH -- skipping PV/DW." | tee -a "$LOG"
        else
            mkdir -p "$OUTPUT_DIR"
            WMH_BIN="${OUTPUT_DIR}/WMH_bin.nii.gz"
            fslmaths "$WMH_MASK" -bin "$WMH_BIN"
            PV_INIT="${OUTPUT_DIR}/PV_region_init.nii.gz"
            fslmaths "$VENT_BIN" -dilM -dilM -dilM -dilM -dilM -dilM -dilM -dilM -dilM -dilM "$PV_INIT"
            PVWMH_INIT="${OUTPUT_DIR}/PVWMH_init.nii.gz"
            fslmaths "$WMH_BIN" -mas "$PV_INIT" "$PVWMH_INIT"
            PVWMH_GROW="$PVWMH"
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
                else
                    mv "$TMP_GROW" "$PVWMH_GROW"
                    ((iter++))
                fi
            done
            fslmaths "$WMH_BIN" -sub "$PVWMH_GROW" -bin "$DWMH"
        fi

        # QC - DWPV
        QC_FILE_DWPV="${QC_DIR}/${SUBJ}_${TP}_DWPV_QC.jpg"
        if [[ -f "$QC_FILE_DWPV" ]]; then
            echo "[exists] QC: $QC_FILE_DWPV -- skipping DWPV QC." | tee -a "$LOG"
        else
            if [[ -f "$DWPV_QC_PY" ]]; then
                python3 "$DWPV_QC_PY" "$OUTPUT_ROOT" "$SUBJ"
            fi
        fi

        # ---- STEP 4: LOBE-WISE OVERLAP ----
        BRAIN_LOBE_DIR="${SUBJ_TP_DIR}/Brain_lobes_outputs"
        COMBINED_CHECK="${BRAIN_LOBE_DIR}/WMH_Frontal_LR.nii.gz"
        if [[ -f "$COMBINED_CHECK" ]]; then
            echo "[exists] $COMBINED_CHECK -- skipping lobe-wise masks." | tee -a "$LOG"
        else
            mkdir -p "$BRAIN_LOBE_DIR"
            declare -A LOBES=(
                [1]="Right_Frontal" [2]="Right_Parietal" [3]="Right_Occipital" [4]="Right_Temporal" [5]="Right_IF_Cerebellum"
                [11]="Left_Frontal" [12]="Left_Parietal" [13]="Left_Occipital" [14]="Left_Temporal" [15]="Left_IF"
            )
            for LABEL in "${!LOBES[@]}"; do
                NAME="${LOBES[$LABEL]}"
                LOBE_MASK="${BRAIN_LOBE_DIR}/WMH_${NAME}.nii.gz"
                fslmaths "$BRAINLOBE_ATLAS" -thr "$LABEL" -uthr "$LABEL" -bin "${BRAIN_LOBE_DIR}/tmp_lobe.nii.gz"
                fslmaths "$WMH_MASK" -mas "${BRAIN_LOBE_DIR}/tmp_lobe.nii.gz" "$LOBE_MASK"
            done
            declare -A COMBINED_LOBES=(
                ["Frontal"]="1,11"
                ["Parietal"]="2,12"
                ["Occipital"]="3,13"
                ["Temporal"]="4,14"
                ["IF_Cerebellum"]="5,15"
            )
            for COMB in "${!COMBINED_LOBES[@]}"; do
                LABELS="${COMBINED_LOBES[$COMB]}"
                COMB_MASK="${BRAIN_LOBE_DIR}/WMH_${COMB}_LR.nii.gz"
                fslmaths "$BRAINLOBE_ATLAS" -thr $(echo $LABELS | cut -d',' -f1) -uthr $(echo $LABELS | cut -d',' -f1) -bin "${BRAIN_LOBE_DIR}/tmp1.nii.gz"
                fslmaths "$BRAINLOBE_ATLAS" -thr $(echo $LABELS | cut -d',' -f2) -uthr $(echo $LABELS | cut -d',' -f2) -bin "${BRAIN_LOBE_DIR}/tmp2.nii.gz"
                fslmaths "${BRAIN_LOBE_DIR}/tmp1.nii.gz" -add "${BRAIN_LOBE_DIR}/tmp2.nii.gz" -bin "${BRAIN_LOBE_DIR}/tmp_lobe.nii.gz"
                fslmaths "$WMH_MASK" -mas "${BRAIN_LOBE_DIR}/tmp_lobe.nii.gz" "$COMB_MASK"
            done
            rm -f "${BRAIN_LOBE_DIR}/tmp1.nii.gz" "${BRAIN_LOBE_DIR}/tmp2.nii.gz" "${BRAIN_LOBE_DIR}/tmp_lobe.nii.gz"
        fi
    done

    echo "All processing for $SUBJ done." | tee -a "$LOG"
done

echo "========== Pipeline Image Processing Finished $(date) ==========" | tee -a "$LOG"

# ---- STEP 5: EXTRACT VOLUMES TO CSV (NO EXTERNAL SCRIPT NEEDED) ----
VOL_CSV="${OUTPUT_ROOT}/WMH_volumes_summary.csv"
echo "[extract_WMHvol-integrated] Extracting volumes to: $VOL_CSV" | tee -a "$LOG"

HEADER="Subject,TP,WMH_mm3,WMH_ml,PVWMH_mm3,PVWMH_ml,DWMH_mm3,DWMH_ml"
HEADER="$HEADER,Left_Frontal_mm3,Left_Frontal_ml,Left_Temporal_mm3,Left_Temporal_ml,Left_Parietal_mm3,Left_Parietal_ml,Left_Occipital_mm3,Left_Occipital_ml,Left_IF_mm3,Left_IF_ml"
HEADER="$HEADER,Right_Frontal_mm3,Right_Frontal_ml,Right_Temporal_mm3,Right_Temporal_ml,Right_Parietal_mm3,Right_Parietal_ml,Right_Occipital_mm3,Right_Occipital_ml,Right_IF_Cerebellum_mm3,Right_IF_Cerebellum_ml"
HEADER="$HEADER,B_Frontal_mm3,B_Frontal_ml,B_Temporal_mm3,B_Temporal_ml,B_Parietal_mm3,B_Parietal_ml,B_Occipital_mm3,B_Occipital_ml,B_IF_Cerebellum_mm3,B_IF_Cerebellum_ml"

echo "$HEADER" > "$VOL_CSV"

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
        SUBJ_TP_DIR="${OUTPUT_ROOT}/${TP}/${SUBJ}"
        if [[ ! -d "$SUBJ_TP_DIR" ]]; then
            continue
        fi
        row="$SUBJ,$TP"
        row="$row,$(get_volumes ${SUBJ_TP_DIR}/WMH_common_inMNI.nii.gz)"
        row="$row,$(get_volumes ${SUBJ_TP_DIR}/DWPV_output/PVWMH.nii.gz)"
        row="$row,$(get_volumes ${SUBJ_TP_DIR}/DWPV_output/DWMH.nii.gz)"
        BRAIN_LOBE_DIR="${SUBJ_TP_DIR}/Brain_lobes_outputs"
        row="$row,$(get_volumes ${BRAIN_LOBE_DIR}/WMH_Left_Frontal.nii.gz)"
        row="$row,$(get_volumes ${BRAIN_LOBE_DIR}/WMH_Left_Temporal.nii.gz)"
        row="$row,$(get_volumes ${BRAIN_LOBE_DIR}/WMH_Left_Parietal.nii.gz)"
        row="$row,$(get_volumes ${BRAIN_LOBE_DIR}/WMH_Left_Occipital.nii.gz)"
        row="$row,$(get_volumes ${BRAIN_LOBE_DIR}/WMH_Left_IF.nii.gz)"
        row="$row,$(get_volumes ${BRAIN_LOBE_DIR}/WMH_Right_Frontal.nii.gz)"
        row="$row,$(get_volumes ${BRAIN_LOBE_DIR}/WMH_Right_Temporal.nii.gz)"
        row="$row,$(get_volumes ${BRAIN_LOBE_DIR}/WMH_Right_Parietal.nii.gz)"
        row="$row,$(get_volumes ${BRAIN_LOBE_DIR}/WMH_Right_Occipital.nii.gz)"
        row="$row,$(get_volumes ${BRAIN_LOBE_DIR}/WMH_Right_IF_Cerebellum.nii.gz)"
        row="$row,$(get_volumes ${BRAIN_LOBE_DIR}/WMH_Frontal_LR.nii.gz)"
        row="$row,$(get_volumes ${BRAIN_LOBE_DIR}/WMH_Temporal_LR.nii.gz)"
        row="$row,$(get_volumes ${BRAIN_LOBE_DIR}/WMH_Parietal_LR.nii.gz)"
        row="$row,$(get_volumes ${BRAIN_LOBE_DIR}/WMH_Occipital_LR.nii.gz)"
        row="$row,$(get_volumes ${BRAIN_LOBE_DIR}/WMH_IF_Cerebellum_LR.nii.gz)"
        echo "$row" >> "$VOL_CSV"
    done
done

echo "========== WMH Volumes Extracted and Summarized $(date) ==========" | tee -a "$LOG"
echo "Summary CSV: $VOL_CSV" | tee -a "$LOG"
