#!/bin/bash
# merge_WMH.sh
# Usage:
#   bash merge_WMH.sh <rootpath> "<TPtomerge>" <filenameIN> <filenameOUT> <SUBJ1> [<SUBJ2> ...]
#
# Example:
#   bash merge_WMH.sh /mnt/hdd/MT/HARMY/HARMY_WMH/derivatives \
#        "BL Y2 Y4Y5" \
#        WMH_common_inMNI.nii.gz \
#        WMH_common_inMNI_merged.nii.gz \
#        sub-HD001 sub-HD002

set -euo pipefail

ROOT=$1
TPs=$2
FILEIN=$3
FILEOUT=$4
shift 4
SUBJECTS=("$@")

for SUBJ in "${SUBJECTS[@]}"; do
    echo ">>> Processing $SUBJ"
    
    TP_ARRAY=($TPs)
    LASTTP=${TP_ARRAY[${#TP_ARRAY[@]}-1]}   # always last timepoint
    OUTDIR="${ROOT}/${LASTTP}/${SUBJ}"
    mkdir -p "$OUTDIR"
    
    MERGED=""
    
    for TP in $TPs; do
        INFILE="${ROOT}/${TP}/${SUBJ}/${FILEIN}"
        if [[ ! -f "$INFILE" ]]; then
            echo "    [!] Missing file: $INFILE"
            continue
        fi
        
        if [[ -z "$MERGED" ]]; then
            # first file becomes starting point
            MERGED="$INFILE"
        else
            # add subsequent masks onto the running merged result
            TMPFILE=$(mktemp --suffix=.nii.gz)
            fslmaths "$MERGED" -add "$INFILE" "$TMPFILE"
            MERGED="$TMPFILE"
        fi
    done
    
    if [[ -n "$MERGED" ]]; then
        fslmaths "$MERGED" -bin "${OUTDIR}/${FILEOUT}"
        echo "    -> Saved merged mask: ${OUTDIR}/${FILEOUT}"
    else
        echo "    [!] No valid input files found for $SUBJ"
    fi
done
