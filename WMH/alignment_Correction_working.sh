#!/bin/bash
# Usage:
#   bash alignment_Correction.sh @sub-HD197
#
# This script aligns WMH mask (FLAIR-native) -> T1 -> T1_common -> MNI.
# Outputs are stored in derivatives/Longitudinal_3TP/BL/<SUBID>/warp_debug

set -euo pipefail

# -----------------------------
# Subject ID (strip leading @)
# -----------------------------
TIMEP="$1"
SUBID="${2#@}"

# -----------------------------
# Directories
# -----------------------------
ROOT="/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives"
CROSS="${ROOT}/Cross_sectional/LSTAI_${TIMEP}/${SUBID}/temp"
COMMON="${ROOT}/Longitudinal_3TP/common"
OUTDIR="${ROOT}/Longitudinal_3TP/${TIMEP}/${SUBID}/warp_debug"
mkdir -p "$OUTDIR"

MNI="/home/admin/Desktop/MRI/MNI/MNI152_T1_1mm_brain.nii.gz"

# -----------------------------
# Inputs
# -----------------------------
WMH_FL="${CROSS}/sub-X_ses-Y_space-flair_seg-lst.nii.gz"
FLAIR="${CROSS}/sub-X_ses-Y_space-flair_FLAIR.nii.gz"
T1="${CROSS}/sub-X_ses-Y_space-t1w_T1w.nii.gz"
T1_COMMON="${COMMON}/${SUBID}_T1_common.nii.gz"

echo "=== Processing $SUBID ==="
echo "WMH native:   $WMH_FL"
echo "FLAIR native: $FLAIR"
echo "T1 native:    $T1"
echo "T1 common:    $T1_COMMON"
echo "MNI:          $MNI"
echo "Output dir:   $OUTDIR"
echo

# -----------------------------
# Check files exist
# -----------------------------
for f in "$WMH_FL" "$FLAIR" "$T1" "$T1_COMMON" "$MNI"; do
    [[ -f "$f" ]] || { echo "ERROR: Missing file: $f"; exit 1; }
done

# -----------------------------
# Step 0: Reorient to std
# -----------------------------
fslreorient2std "$FLAIR"     "${OUTDIR}/FLAIR_reor.nii.gz"
fslreorient2std "$T1"        "${OUTDIR}/T1_reor.nii.gz"
fslreorient2std "$T1_COMMON" "${OUTDIR}/T1common_reor.nii.gz"
fslreorient2std "$WMH_FL"    "${OUTDIR}/WMH_reor.nii.gz"

# -----------------------------
# Step 1: FLAIR -> T1
# -----------------------------
flirt -in "${OUTDIR}/FLAIR_reor.nii.gz" \
-ref "${OUTDIR}/T1_reor.nii.gz" \
-omat "${OUTDIR}/FLAIR_to_T1.mat" \
-dof 6 \
-out "${OUTDIR}/FLAIR_inT1.nii.gz"

flirt -in "${OUTDIR}/WMH_reor.nii.gz" \
-ref "${OUTDIR}/T1_reor.nii.gz" \
-applyxfm -init "${OUTDIR}/FLAIR_to_T1.mat" \
-interp nearestneighbour \
-out "${OUTDIR}/WMH_inT1.nii.gz"

# -----------------------------
# Step 2: T1 -> T1_common
# -----------------------------
flirt -in "${OUTDIR}/T1_reor.nii.gz" \
-ref "${OUTDIR}/T1common_reor.nii.gz" \
-omat "${OUTDIR}/T1_to_common.mat" \
-dof 12 \
-out "${OUTDIR}/T1_inCommon.nii.gz"

flirt -in "${OUTDIR}/FLAIR_inT1.nii.gz" \
-ref "${OUTDIR}/T1common_reor.nii.gz" \
-applyxfm -init "${OUTDIR}/T1_to_common.mat" \
-interp trilinear \
-out "${OUTDIR}/FLAIR_inCommon.nii.gz"

flirt -in "${OUTDIR}/WMH_inT1.nii.gz" \
-ref "${OUTDIR}/T1common_reor.nii.gz" \
-applyxfm -init "${OUTDIR}/T1_to_common.mat" \
-interp nearestneighbour \
-out "${OUTDIR}/WMH_inCommon.nii.gz"

# -----------------------------
# Step 3: T1_common -> MNI
# -----------------------------
flirt -in "${OUTDIR}/T1common_reor.nii.gz" \
-ref "$MNI" \
-omat "${OUTDIR}/common_to_MNI.mat" \
-dof 12 \
-out "${OUTDIR}/T1common_inMNI.nii.gz"

flirt -in "${OUTDIR}/FLAIR_inCommon.nii.gz" \
-ref "$MNI" \
-applyxfm -init "${OUTDIR}/common_to_MNI.mat" \
-interp trilinear \
-out "${OUTDIR}/FLAIR_inMNI.nii.gz"

flirt -in "${OUTDIR}/WMH_inCommon.nii.gz" \
-ref "$MNI" \
-applyxfm -init "${OUTDIR}/common_to_MNI.mat" \
-interp nearestneighbour \
-out "${OUTDIR}/WMH_inMNI.nii.gz"

# Binarize WMH final
fslmaths "${OUTDIR}/WMH_inMNI.nii.gz" -bin "${OUTDIR}/WMH_inMNI_bin.nii.gz"

echo "=== Finished $SUBID. Outputs in $OUTDIR ==="
ls -lh "$OUTDIR"/*inMNI*.nii.gz
