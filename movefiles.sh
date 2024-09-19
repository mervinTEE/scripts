#!/bin/bash

#To look through different folders and move dicoms from files and remove files
for subject in /mnt/hdd/MT/NEURO_BMC/NEURO_ASL/sourcedata/NEURO-*/; do
    find "$subject/scans/" -type d \( \
    -name "*SAG_MPRAGE*" -o \
    -name "*Perfusion_Images*" -o \
    -name "*Encoded_Images*" -o \
    -name "*T2_TSE_FLAIR*" -o \
    -name "*ss_TE00_TI*" \
    \) -exec sh -c '
        mv "$1/resources/DICOM/files/"* "$1/resources/DICOM/" &&
    rmdir "$1/resources/DICOM/files/" 2>/dev/null || true' _ {} \;
done
