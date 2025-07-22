# FOR SINGLE SUJBECT


# STEP 2: Registering T1w to Common Template []
## Creating output directories for registration results
mkdir -p $BASELINEOUT/sub-HD106/REG
mkdir -p $Y2OUT/sub-HD106/REG
mkdir -p $Y4Y5OUT/sub-HD106/REG

## For BL [x]
flirt -in $BASELINE/sub-HD106/anat/sub-HD106_run-1_T1w.nii.gz \
-ref $TEMP/sub-HD106_commontemp.nii.gz \
-omat $BASELINEOUT/sub-HD106/REG/sub-HD106_T1_to_common.mat \
-out $BASELINEOUT/sub-HD106/REG/sub-HD106_T1_to_common.nii.gz \
-dof 6

## For Y2 [x]
flirt -in $Y2/sub-HD106/anat/sub-HD106_run-1_T1w.nii.gz \
-ref $TEMP/sub-HD106_commontemp.nii.gz \
-omat $Y2OUT/sub-HD106/REG/sub-HD106_T1_to_common.mat \
-out $Y2OUT/sub-HD106/REG/sub-HD106_T1_to_common.nii.gz \
-dof 6

## For Y4Y5 [x]
flirt -in $Y4Y5/sub-HD106/anat/sub-HD106_run-1_T1w.nii.gz \
-ref $TEMP/sub-HD106_commontemp.nii.gz \
-omat $Y4Y5OUT/sub-HD106/REG/sub-HD106_T1_to_common.mat \
-out $Y4Y5OUT/sub-HD106/REG/sub-HD106_T1_to_common.nii.gz \
-dof 6

# STEP 3: Registering FLAIR to T1 Native []
## For BL [x]
flirt -in $BASELINE/sub-HD106/anat/sub-HD106_run-1_FLAIR.nii.gz \
-ref $BASELINE/sub-HD106/anat/sub-HD106_run-1_T1w.nii.gz \
-omat $BASELINEOUT/sub-HD106/REG/sub-HD106_FLAIR_to_T1.mat \
-out $BASELINEOUT/sub-HD106/REG/sub-HD106_FLAIR_to_T1.nii.gz \
-dof 6

## For Y2 [x]
flirt -in $Y2/sub-HD106/anat/sub-HD106_run-1_FLAIR.nii.gz \
-ref $Y2/sub-HD106/anat/sub-HD106_run-1_T1w.nii.gz \
-omat $Y2OUT/sub-HD106/REG/sub-HD106_FLAIR_to_T1.mat \
-out $Y2OUT/sub-HD106/REG/sub-HD106_FLAIR_to_T1.nii.gz \
-dof 6

## For Y4Y5 [x]
flirt -in $Y4Y5/sub-HD106/anat/sub-HD106_run-1_FLAIR.nii.gz \
-ref $Y4Y5/sub-HD106/anat/sub-HD106_run-1_T1w.nii.gz \
-omat $Y4Y5OUT/sub-HD106/REG/sub-HD106_FLAIR_to_T1.mat \
-out $Y4Y5OUT/sub-HD106/REG/sub-HD106_FLAIR_to_T1.nii.gz \
-dof 6

# STEP 4: Registering FLAIR (in T1 Space) to Common Template []
## For BL [x]
flirt -in $BASELINEOUT/sub-HD106/REG/sub-HD106_FLAIR_to_T1.nii.gz \
-ref $TEMP/sub-HD106_commontemp.nii.gz \
-applyxfm \
-init $BASELINEOUT/sub-HD106/REG/sub-HD106_T1_to_common.mat \
-out $BASELINEOUT/sub-HD106/REG/sub-HD106_FLAIR_to_common.nii.gz \
-dof 6

## For Y2 [x]
flirt -in $Y2OUT/sub-HD106/REG/sub-HD106_FLAIR_to_T1.nii.gz \
-ref $TEMP/sub-HD106_commontemp.nii.gz \
-applyxfm \
-init $Y2OUT/sub-HD106/REG/sub-HD106_T1_to_common.mat \
-out $Y2OUT/sub-HD106/REG/sub-HD106_FLAIR_to_common.nii.gz \
-dof 6

## For Y4Y5 [x]
flirt -in $Y4Y5OUT/sub-HD106/REG/sub-HD106_FLAIR_to_T1.nii.gz \
-ref $TEMP/sub-HD106_commontemp.nii.gz \
-applyxfm \
-init $Y4Y5OUT/sub-HD106/REG/sub-HD106_T1_to_common.mat \
-out $Y4Y5OUT/sub-HD106/REG/sub-HD106_FLAIR_to_common.nii.gz \
-dof 6

# STEP 5: Combine Transforms of T1_to_common and FLAIR_to_T1 for WMH_to_common []
## For BL [x]
convert_xfm -omat $BASELINEOUT/sub-HD106/REG/sub-HD106_WMH_to_common.mat \
-concat $BASELINEOUT/sub-HD106/REG/sub-HD106_T1_to_common.mat \
$BASELINEOUT/sub-HD106/REG/sub-HD106_FLAIR_to_T1.mat

## For Y2 [x]
convert_xfm -omat $Y2OUT/sub-HD106/REG/sub-HD106_WMH_to_common.mat \
-concat $Y2OUT/sub-HD106/REG/sub-HD106_T1_to_common.mat \
$Y2OUT/sub-HD106/REG/sub-HD106_FLAIR_to_T1.mat

## For Y4Y5 [x]
convert_xfm -omat $Y4Y5OUT/sub-HD106/REG/sub-HD106_WMH_to_common.mat \
-concat $Y4Y5OUT/sub-HD106/REG/sub-HD106_T1_to_common.mat \
$Y4Y5OUT/sub-HD106/REG/sub-HD106_FLAIR_to_T1.mat

# STEP 6: Apply Combined Transform to WMH [x]
export derivatives=/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives
export WMHout=$derivatives/Longitudinal

## For BL [x]
mkdir -p $WMHout/bl/sub-HD106

flirt -in $derivatives/Cross_sectional/LSTAI_BL/sub-HD106/temp/sub-X_ses-Y_space-flair_seg-lst_edited.nii.gz \
-ref $TEMP/sub-HD106_commontemp.nii.gz \
-applyxfm \
-init $BASELINEOUT/sub-HD106/REG/sub-HD106_WMH_to_common.mat \
-out $WMHout/bl/sub-HD106/sub-HD106_WMH_to_common.nii.gz \
-dof 6

## For Y2 [x]
mkdir -p $WMHout/y2/sub-HD106

flirt -in $derivatives/Cross_sectional/LSTAI_Y2/sub-HD106/temp/sub-X_ses-Y_space-flair_seg-lst_edited.nii.gz \
-ref $TEMP/sub-HD106_commontemp.nii.gz \
-applyxfm \
-init $Y2OUT/sub-HD106/REG/sub-HD106_WMH_to_common.mat \
-out $WMHout/y2/sub-HD106/sub-HD106_WMH_to_common.nii.gz \
-dof 6

## For Y4Y5 [x]
mkdir -p $WMHout/y4y5/sub-HD106

flirt -in $derivatives/Cross_sectional/LSTAI_Y4Y5/temp/sub-HD106/sub-X_ses-Y_space-flair_seg-lst_edited.nii.gz \
-ref $TEMP/sub-HD106_commontemp.nii.gz \
-applyxfm \
-init $Y4Y5OUT/sub-HD106/REG/sub-HD106_WMH_to_common.mat \
-out $WMHout/y4y5/sub-HD106/sub-HD106_WMH_to_common.nii.gz \
-dof 6

# STEP 7: Registering Common Template to MNI
mkdir -p /mnt/hdd/MT/HARMY/HARMY_WMH/regdata_quick/MNI_common_template
export MNIout=/mnt/hdd/MT/HARMY/HARMY_WMH/regdata_quick/MNI_common_template

flirt -in $TEMP/sub-HD106_commontemp.nii.gz \
-ref $MNI \
-omat $MNIout/sub-HD106_commontemp_to_MNI.mat \
-out $MNIout/sub-HD106_commontemp_to_MNI.nii.gz \
-dof 12


# STEP 8: Apply Common Template to MNI Transform to WMH
## For BL [x]
flirt -in $WMHout/bl/sub-HD106/sub-HD106_WMH_to_common.nii.gz \
-ref $MNI \
-applyxfm \
-init $MNIout/sub-HD106_commontemp_to_MNI.mat \
-out $WMHout/bl/sub-HD106/sub-HD106_WMH_to_MNI.nii.gz \
-dof 12


## For Y2 [x]
flirt -in $WMHout/y2/sub-HD106/sub-HD106_WMH_to_common.nii.gz \
-ref $MNI \
-applyxfm \
-init $MNIout/sub-HD106_commontemp_to_MNI.mat \
-out $WMHout/y2/sub-HD106/sub-HD106_WMH_to_MNI.nii.gz \
-dof 12


## For Y4Y5 [x]
flirt -in $WMHout/y4y5/sub-HD106/sub-HD106_WMH_to_common.nii.gz \
-ref $MNI \
-applyxfm \
-init $MNIout/sub-HD106_commontemp_to_MNI.mat \
-out $WMHout/y4y5/sub-HD106/sub-HD106_WMH_to_MNI.nii.gz \
-dof 12


# STEP 9: Registering FLAIR in Common Template to MNI

## For BL [x]
flirt -in $BASELINEOUT/sub-HD106/REG/sub-HD106_FLAIR_to_common.nii.gz \
-ref $MNI \
-applyxfm \
-init $MNIout/sub-HD106_commontemp_to_MNI.mat \
-out $BASELINEOUT/sub-HD106/REG/sub-HD106_FLAIR_to_MNI.nii.gz \
-dof 12

## For Y2 [x]
flirt -in $Y2OUT/sub-HD106/REG/sub-HD106_FLAIR_to_common.nii.gz \
-ref $MNI \
-applyxfm \
-init $MNIout/sub-HD106_commontemp_to_MNI.mat \
-out $Y2OUT/sub-HD106/REG/sub-HD106_FLAIR_to_MNI.nii.gz \
-dof 12

## For Y4Y5 [x]
flirt -in $Y4Y5OUT/sub-HD106/REG/sub-HD106_FLAIR_to_common.nii.gz \
-ref $MNI \
-applyxfm \
-init $MNIout/sub-HD106_commontemp_to_MNI.mat \
-out $Y4Y5OUT/sub-HD106/REG/sub-HD106_FLAIR_to_MNI.nii.gz \
-dof 12

# STEP 10: Registering T1 in Common Template to MNI (Optional)
## For BL []
flirt -in $BASELINEOUT/sub-HD106/REG/sub-HD106_T1_to_common.nii.gz \
-ref $MNI \
-applyxfm \
-init $MNIout/sub-HD106_commontemp_to_MNI.mat \
-out $BASELINEOUT/sub-HD106/REG/sub-HD106_T1_to_MNI.nii.gz \
-dof 12
## For Y2 []
flirt -in $Y2OUT/sub-HD106/REG/sub-HD106_T1_to_common.nii.gz \
-ref $MNI \
-applyxfm \
-init $MNIout/sub-HD106_commontemp_to_MNI.mat \
-out $Y2OUT/sub-HD106/REG/sub-HD106_T1_to_MNI.nii.gz \
-dof 12
## For Y4Y5 []
flirt -in $Y4Y5OUT/sub-HD106/REG/sub-HD106_T1_to_common.nii.gz \
-ref $MNI \
-applyxfm \
-init $MNIout/sub-HD106_commontemp_to_MNI.mat \
-out $Y4Y5OUT/sub-HD106/REG/sub-HD106_T1_to_MNI.nii.gz \
-dof 12
