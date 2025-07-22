export BASELINE=/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Cross_sectional/Original_LST_BL_Corrected/temp
export Y2=/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_Y2
export Y4Y5=/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_Y4Y5
export BASELINEOUT=/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/bl
export Y2OUT=/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/y2
export Y4Y5OUT=/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/y4y5
export TEMP=/mnt/hdd/MT/HARMY/HARMY_WMH/regdata_quick/common_template
export MNI=$FSLDIR/data/standard/MNI152_T1_1mm.nii.gz

#STEP 1: Generating Common Template (intra-subject) []
###### To run in this seqeuence, such that those with three time points are processed last ######

## BL and Y2 Time Points  []
for_each -nthreads 20 -info $BASELINE/* : mri_robust_template \
--mov $BASELINE/NAME/anat/NAME_run-1_T1w.nii.gz \
$Y2/NAME/anat/NAME_run-1_T1w.nii.gz \
--average 1 \
--template $TEMP/NAME_commontemp.nii.gz \
--satit
## BL and Y4Y5 Time Points []
for_each -nthreads 20 -info $BASELINE/* : mri_robust_template \
--mov $BASELINE/NAME/anat/NAME_run-1_T1w.nii.gz \
$Y4Y5/NAME/anat/NAME_run-1_T1w.nii.gz \
--average 1 \
--template $TEMP/NAME_commontemp.nii.gz \
--satit
## Y2 and Y4Y5 Time Points []
for_each -nthreads 20 -info $Y2/* : mri_robust_template \
--mov $Y2/NAME/anat/NAME_run-1_T1w.nii.gz \
$Y4Y5/NAME/anat/NAME_run-1_T1w.nii.gz \
--average 1 \
--template $TEMP/NAME_commontemp.nii.gz \
--satit

## Three time points []
for_each -nthreads 20 -info $BASELINE/* : mri_robust_template \
--mov $BASELINE/NAME/anat/NAME_run-1_T1w.nii.gz \
$Y2/NAME/anat/NAME_run-1_T1w.nii.gz \
$Y4Y5/NAME/anat/NAME_run-1_T1w.nii.gz \
--average 1 \
--template $TEMP/NAME_commontemp.nii.gz \
--satit


# STEP 2: Registering T1w to Common Template []
## Creating output directories for registration results
for_each -nthreads 20 -info $BASELINE/* : mkdir -p $BASELINEOUT/NAME/REG
for_each -nthreads 20 -info $Y2/* : mkdir -p $Y2OUT/NAME/REG
for_each -nthreads 20 -info $Y4Y5/* : mkdir -p $Y4Y5OUT/NAME/REG

## For BL [x]
for_each -nthreads 20 -info $BASELINE/* : flirt -in $BASELINE/NAME/sub-X_ses-Y_space-t1w_T1w.nii.gz \
-ref $TEMP/NAME_commontemp.nii.gz \
-omat $BASELINEOUT/NAME/REG/NAME_T1_to_common.mat \
-out $BASELINEOUT/NAME/REG/NAME_T1_to_common.nii.gz \
-dof 6

## For Y2 []
for_each -nthreads 20 -info $Y2/* : flirt -in $Y2/NAME/anat/NAME_run-1_T1w.nii.gz \
-ref $TEMP/NAME_commontemp.nii.gz \
-omat $Y2OUT/NAME/REG/NAME_T1_to_common.mat \
-out $Y2OUT/NAME/REG/NAME_T1_to_common.nii.gz \
-dof 6

## For Y4Y5 []
for_each -nthreads 20 -info $Y4Y5/* : flirt -in $Y4Y5/NAME/anat/NAME_run-1_T1w.nii.gz \
-ref $TEMP/NAME_commontemp.nii.gz \
-omat $Y4Y5OUT/NAME/REG/NAME_T1_to_common.mat \
-out $Y4Y5OUT/NAME/REG/NAME_T1_to_common.nii.gz \
-dof 6

# STEP 3: Registering FLAIR to T1 Native []
## For BL [x]
for_each -nthreads 20 -info $BASELINE/* : flirt -in $BASELINE/NAME/sub-X_ses-Y_space-flair_FLAIR.nii.gz \
-ref $BASELINE/NAME/sub-X_ses-Y_space-t1w_T1w.nii.gz \
-omat $BASELINEOUT/NAME/REG/NAME_FLAIR_to_T1.mat \
-out $BASELINEOUT/NAME/REG/NAME_FLAIR_to_T1.nii.gz \
-dof 6

## For Y2 []
for_each -nthreads 20 -info $Y2/* : flirt -in $Y2/NAME/anat/NAME_run-1_FLAIR.nii.gz \
-ref $Y2/NAME/anat/NAME_run-1_T1w.nii.gz \
-omat $Y2OUT/NAME/REG/NAME_FLAIR_to_T1.mat \
-out $Y2OUT/NAME/REG/NAME_FLAIR_to_T1.nii.gz \
-dof 6

## For Y4Y5 []
for_each -nthreads 20 -info $Y4Y5/* : flirt -in $Y4Y5/NAME/anat/NAME_run-1_FLAIR.nii.gz \
-ref $Y4Y5/NAME/anat/NAME_run-1_T1w.nii.gz \
-omat $Y4Y5OUT/NAME/REG/NAME_FLAIR_to_T1.mat \
-out $Y4Y5OUT/NAME/REG/NAME_FLAIR_to_T1.nii.gz \
-dof 6

# STEP 4: Registering FLAIR (in T1 Space) to Common Template []
## For BL [x]
for_each -nthreads 20 -info $BASELINE/* : flirt -in $BASELINEOUT/NAME/REG/NAME_FLAIR_to_T1.nii.gz \
-ref $TEMP/NAME_commontemp.nii.gz \
-applyxfm \
-init $BASELINEOUT/NAME/REG/NAME_T1_to_common.mat \
-out $BASELINEOUT/NAME/REG/NAME_FLAIR_to_common.nii.gz \
-dof 6

## For Y2 []
for_each -nthreads 20 -info $Y2/* : flirt -in $Y2OUT/NAME/REG/NAME_FLAIR_to_T1.nii.gz \
-ref $TEMP/NAME_commontemp.nii.gz \
-applyxfm \
-init $Y2OUT/NAME/REG/NAME_T1_to_common.mat \
-out $Y2OUT/NAME/REG/NAME_FLAIR_to_common.nii.gz \
-dof 6

## For Y4Y5 []
for_each -nthreads 20 -info $Y4Y5/* : flirt -in $Y4Y5OUT/NAME/REG/NAME_FLAIR_to_T1.nii.gz \
-ref $TEMP/NAME_commontemp.nii.gz \
-applyxfm \
-init $Y4Y5OUT/NAME/REG/NAME_T1_to_common.mat \
-out $Y4Y5OUT/NAME/REG/NAME_FLAIR_to_common.nii.gz \
-dof 6

# STEP 5: Combine Transforms of T1_to_common and FLAIR_to_T1 for WMH_to_common []
## For BL [x]
for_each -nthreads 20 -info $BASELINE/* : convert_xfm -omat $BASELINEOUT/NAME/REG/NAME_WMH_to_common.mat \
-concat $BASELINEOUT/NAME/REG/NAME_T1_to_common.mat \
$BASELINEOUT/NAME/REG/NAME_FLAIR_to_T1.mat

## For Y2 []
for_each -nthreads 20 -info $Y2/* : convert_xfm -omat $Y2OUT/NAME/REG/NAME_WMH_to_common.mat \
-concat $Y2OUT/NAME/REG/NAME_T1_to_common.mat \
$Y2OUT/NAME/REG/NAME_FLAIR_to_T1.mat

## For Y4Y5 []
for_each -nthreads 20 -info $Y4Y5/* : convert_xfm -omat $Y4Y5OUT/NAME/REG/NAME_WMH_to_common.mat \
-concat $Y4Y5OUT/NAME/REG/NAME_T1_to_common.mat \
$Y4Y5OUT/NAME/REG/NAME_FLAIR_to_T1.mat

# STEP 6: Apply Combined Transform to WMH []
export derivatives=/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives
export WMHout=$derivatives/Longitudinal

## For BL [x]
for_each -nthreads 20 -info $BASELINE/* : mkdir -p $WMHout/bl/NAME

for_each -nthreads 20 -info $BASELINE/* : flirt -in $derivatives/Cross_sectional/Original_LST_BL_Corrected/temp/NAME/sub-X_ses-Y_space-flair_seg-lst.nii.gz \
-ref $TEMP/NAME_commontemp.nii.gz \
-applyxfm \
-init $BASELINEOUT/NAME/REG/NAME_WMH_to_common.mat \
-out $WMHout/bl/NAME/NAME_WMH_to_common.nii.gz \
-dof 6

## For Y2 [next step]
for_each -nthreads 20 -info $Y2/* : mkdir -p $WMHout/y2/NAME

for_each -nthreads 20 -info $Y2/* : flirt -in $derivatives/Cross_sectional/LSTAI_Y2/NAME/temp/sub-X_ses-Y_space-flair_seg-lst_edited.nii.gz \
-ref $TEMP/NAME_commontemp.nii.gz \
-applyxfm \
-init $Y2OUT/NAME/REG/NAME_WMH_to_common.mat \
-out $WMHout/y2/NAME/NAME_WMH_to_common.nii.gz \
-dof 6

## For Y4Y5 []
for_each -nthreads 20 -info $Y4Y5/* : mkdir -p $WMHout/y4y5/NAME

for_each -nthreads 20 -info $Y4Y5/* : flirt -in $derivatives/Cross_sectional/LSTAI_Y4Y5/temp/NAME/sub-X_ses-Y_space-flair_seg-lst_edited.nii.gz \
-ref $TEMP/NAME_commontemp.nii.gz \
-applyxfm \
-init $Y4Y5OUT/NAME/REG/NAME_WMH_to_common.mat \
-out $WMHout/y4y5/NAME/NAME_WMH_to_common.nii.gz \
-dof 6

# STEP 7: Registering Common Template to MNI [x]
mkdir -p /mnt/hdd/MT/HARMY/HARMY_WMH/regdata_quick/MNI_common_template
export MNIout=/mnt/hdd/MT/HARMY/HARMY_WMH/regdata_quick/MNI_common_template

for_each -nthreads 20 -info $BASELINEOUT/* : flirt -in $TEMP/NAME_commontemp.nii.gz \
-ref $MNI \
-omat $MNIout/NAME_commontemp_to_MNI.mat \
-out $MNIout/NAME_commontemp_to_MNI.nii.gz \
-dof 12

# STEP 8: Apply Common Template to MNI Transform to WMH
## For BL [x]
for_each -nthreads 20 -info $WMHout/bl/* : flirt -in $WMHout/bl/NAME/NAME_WMH_to_common.nii.gz \
-ref $MNI \
-applyxfm \
-init $MNIout/NAME_commontemp_to_MNI.mat \
-out $WMHout/bl/NAME/NAME_WMH_to_MNI.nii.gz \
-dof 12

## For Y2 []
for_each -nthreads 20 -info $WMHout/y2/* : flirt -in $WMHout/y2/NAME/NAME_WMH_to_common.nii.gz \
-ref $MNI \
-applyxfm \
-init $MNIout/NAME_commontemp_to_MNI.mat \
-out $WMHout/y2/NAME/NAME_WMH_to_MNI.nii.gz \
-dof 12

## For Y4Y5 []
for_each -nthreads 20 -info $WMHout/y4y5/* : flirt -in $WMHout/y4y5/NAME/NAME_WMH_to_common.nii.gz \
-ref $MNI \
-applyxfm \
-init $MNIout/NAME_commontemp_to_MNI.mat \
-out $WMHout/y4y5/NAME/NAME_WMH_to_MNI.nii.gz \
-dof 12

# STEP 9: Registering FLAIR in Common Template to MNI

## For BL [x]
for_each -nthreads 20 -info $BASELINEOUT/* : flirt -in $BASELINEOUT/NAME/REG/NAME_FLAIR_to_common.nii.gz \
-ref $MNI \
-applyxfm \
-init $MNIout/NAME_commontemp_to_MNI.mat \
-out $BASELINEOUT/NAME/REG/NAME_FLAIR_to_MNI.nii.gz \
-dof 12

## For Y2 []
for_each -nthreads 20 -info $Y2OUT/* : flirt -in $Y2OUT/NAME/REG/NAME_FLAIR_to_common.nii.gz \
-ref $MNI \
-applyxfm \
-init $MNIout/NAME_commontemp_to_MNI.mat \
-out $Y2OUT/NAME/REG/NAME_FLAIR_to_MNI.nii.gz \
-dof 12

## For Y4Y5 []
for_each -nthreads 20 -info $Y4Y5OUT/* : flirt -in $Y4Y5OUT/NAME/REG/NAME_FLAIR_to_common.nii.gz \
-ref $MNI \
-applyxfm \
-init $MNIout/NAME_commontemp_to_MNI.mat \
-out $Y4Y5OUT/NAME/REG/NAME_FLAIR_to_MNI.nii.gz \
-dof 12

# STEP 10: Registering T1 in Common Template to MNI (Optional)
## For BL [x]
for_each -nthreads 20 -info $BASELINEOUT/* : flirt -in $BASELINEOUT/NAME/REG/NAME_T1_to_common.nii.gz \
-ref $MNI \
-applyxfm \
-init $MNIout/NAME_commontemp_to_MNI.mat \
-out $BASELINEOUT/NAME/REG/NAME_T1_to_MNI.nii.gz \
-dof 12
## For Y2 []
for_each -nthreads 20 -info $Y2OUT/* : flirt -in $Y2OUT/NAME/REG/NAME_T1_to_common.nii.gz \
-ref $MNI \
-applyxfm \
-init $MNIout/NAME_commontemp_to_MNI.mat \
-out $Y2OUT/NAME/REG/NAME_T1_to_MNI.nii.gz \
-dof 12
## For Y4Y5 []
for_each -nthreads 20 -info $Y4Y5OUT/* : flirt -in $Y4Y5OUT/NAME/REG/NAME_T1_to_common.nii.gz \
-ref $MNI \
-applyxfm \
-init $MNIout/NAME_commontemp_to_MNI.mat \
-out $Y4Y5OUT/NAME/REG/NAME_T1_to_MNI.nii.gz \
-dof 12

# STEP 11: Segmentating WMH in MNI space into ROIs using FSL templates
export ROIs=/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/ROIs
for_each -nthreads 20 -info $WMHout/BL/* : mkdir -p $ROIs/BL/NAME
for_each -nthreads 20 -info $WMHout/Y2/* : mkdir -p $ROIs/Y2/NAME
for_each -nthreads 20 -info $WMHout/Y4Y5/* : mkdir -p $ROIs/Y4Y5/NAME

## For BL []
WMH=WMH_sub-HD001_inMNI.nii.gz

fslmaths $WMH -mas ACA_mask.nii.gz WMH_ACA_sub-HD001.nii.gz
fslmaths $WMH -mas MCA_mask.nii.gz WMH_MCA_sub-HD001.nii.gz
fslmaths $WMH -mas PCA_mask.nii.gz WMH_PCA_sub-HD001.nii.gz



#####################################################################################################
########################### Code to check for files #################################################
#####################################################################################################

#!/bin/bash

# Set the base directory where all subject folders are
BASE_DIR="/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/bl"
Y2_DIR="/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/y2"
Y4Y5_DIR="/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/y4y5"
# Output CSV file
csvfolder=/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/csv
mkdir -p "$csvfolder"
BL_OUTPUT_CSV="$csvfolder/BL_reg_file_counts.csv"
Y2_OUTPUT_CSV="$csvfolder/Y2_reg_file_counts.csv"
Y4Y5_OUTPUT_CSV="$csvfolder/Y4Y5_reg_file_counts.csv"

# Write header
echo "SubjectID,REG_FileCount" > "$BL_OUTPUT_CSV"
echo "SubjectID,REG_FileCount" > "$Y2_OUTPUT_CSV"
echo "SubjectID,REG_FileCount" > "$Y4Y5_OUTPUT_CSV"

# Loop through each subject folder for BL
for SUBJ_DIR in "$BASE_DIR"/sub-*/; do
    SUBJ_ID=$(basename "$SUBJ_DIR")
    REG_DIR="$SUBJ_DIR/REG"
    
    if [ -d "$REG_DIR" ]; then
        COUNT=$(find "$REG_DIR" -type f | wc -l)
    else
        COUNT=0
    fi
    
    echo "$SUBJ_ID,$COUNT" >> "$BL_OUTPUT_CSV"
done

echo "✅ File counts exported to $BL_OUTPUT_CSV"

# Loop through each subject folder for Y2
for SUBJ_DIR in "$Y2_DIR"/sub-*/; do
    SUBJ_ID=$(basename "$SUBJ_DIR")
    REG_DIR="$SUBJ_DIR/REG"
    
    if [ -d "$REG_DIR" ]; then
        COUNT=$(find "$REG_DIR" -type f | wc -l)
    else
        COUNT=0
    fi
    
    echo "$SUBJ_ID,$COUNT" >> "$Y2_OUTPUT_CSV"
done

echo "✅ File counts exported to $Y2_OUTPUT_CSV"

# Loop through each subject folder for Y4Y5
for SUBJ_DIR in "$Y4Y5_DIR"/sub-*/; do
    SUBJ_ID=$(basename "$SUBJ_DIR")
    REG_DIR="$SUBJ_DIR/REG"
    
    if [ -d "$REG_DIR" ]; then
        COUNT=$(find "$REG_DIR" -type f | wc -l)
    else
        COUNT=0
    fi
    
    echo "$SUBJ_ID,$COUNT" >> "$Y4Y5_OUTPUT_CSV"
done

echo "✅ File counts exported to $Y4Y5_OUTPUT_CSV"


#####################################################################################################
########################### Code to check for all time points (to use in R)##########################
#####################################################################################################

library(dplyr)
library(stringr)

# Define root directories
roots <- list(
    BL = "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL",
    Y2 = "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_Y2",
    Y4Y5 = "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_Y4Y5"
)

# Get all unique subject IDs
all_subjects <- unique(unlist(lapply(roots, function(path) {
                dirs <- list.dirs(path, recursive = FALSE)
                basename(dirs[grepl("sub-", basename(dirs))])
})))

# Initialize results list
results <- list()

# Iterate through all subjects
for (subj in all_subjects) {
    found_timepoints <- c()
    flair_and_t1_all_present <- TRUE
    
    for (tp in names(roots)) {
        anat_path <- file.path(roots[[tp]], subj, "anat")
        
        if (dir.exists(anat_path)) {
            files <- list.files(anat_path, pattern = "\\.nii\\.gz$", full.names = TRUE)
            flair_present <- any(str_detect(files, "FLAIR"))
            t1_present <- any(str_detect(files, "T1"))
            
            found_timepoints <- c(found_timepoints, tp)
            
            if (!(flair_present && t1_present)) {
                flair_and_t1_all_present <- FALSE
            }
        }
    }
    
    tp_count <- length(found_timepoints)
    has_all <- ifelse(tp_count == 3, "Yes", "No")
    has_two <- ifelse(tp_count >= 2, "Yes", "No")
    which_two <- ifelse(tp_count == 2, paste(found_timepoints, collapse = " and "), "")
    only_one <- ifelse(tp_count == 1, "Yes", "No")
    only_tp <- ifelse(tp_count == 1, found_timepoints[1], "")
    flair_and_t1 <- ifelse(flair_and_t1_all_present && tp_count > 0, "Yes", "No")
    
    results[[length(results) + 1]] <- data.frame(
        subj_id = subj,
        has_all_timepoints = has_all,
        has_at_least_two_timepoints = has_two,
        which_two_timepoints = which_two,
        only_one_timepoint = only_one,
        only_in_timepoint = only_tp,
        has_flair_and_t1 = flair_and_t1,
        stringsAsFactors = FALSE
    )
}

# Combine and save to CSV
results_df <- bind_rows(results)
write.csv(results_df, "subject_summary.csv", row.names = FALSE)