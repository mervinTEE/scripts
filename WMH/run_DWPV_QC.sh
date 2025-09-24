#!/bin/bash
# run_DWPV_QC.sh
# Wrapper to run DWPV_QC.py with custom slice indices
#
# Usage:
# bash run_DWPV_QC.sh <BASE_DIR> "[slice_indices]" <SUBJ1> [<SUBJ2> ...]
# Example:
# bash run_DWPV_QC.sh /mnt/hdd/... "[-15 0 10 20 30]" sub-HD001 sub-HD002 sub-HD035

set -euo pipefail

BASE_DIR="$1"
SLICE_STR="$2"
shift 2
SUBJECTS=("$@")

# Clean up brackets and convert to space-separated list
SLICE_STR=$(echo "$SLICE_STR" | tr -d '[]')
SLICE_LIST=$(echo $SLICE_STR)

for SUBJ in "${SUBJECTS[@]}"; do
    echo ">>> Running QC for $SUBJ with slices [$SLICE_LIST]"
    python3 /home/admin/Desktop/MRIapp/scripts/WMH/DWPV_QC.py "$BASE_DIR" "$SUBJ" $SLICE_LIST
done
