# FS Stream
export BASELINE=/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL
export Y2=/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_Y2
export Y4Y5=/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_Y4Y5
export TEMP=/mnt/hdd/MT/HARMY/HARMY_WMH/regdata/common_template
export MISSING=/mnt/hdd/MT/HARMY/HARMY_WMH/regdata/y2/missing
export MISSINGBL=/mnt/hdd/MT/HARMY/HARMY_WMH/regdata/y2/missing/BL
export MISSINGY2=/mnt/hdd/MT/HARMY/HARMY_WMH/regdata/y2/missing/Y2
export MISSINGY4Y5=/mnt/hdd/MT/HARMY/HARMY_WMH/regdata/y2/missing/Y4Y5
##############################################################################################
############################################Common Template###################################
##############################################################################################
#Generating Common Template (intra-subject) [x]
## Three time points
for_each -nthreads 15 -info $BASELINE/* : mri_robust_template \
--mov $BASELINE/NAME/anat/NAME_run-1_T1w.nii.gz \
$Y2/NAME/anat/NAME_run-1_T1w.nii.gz \
$Y4Y5/NAME/anat/NAME_run-1_T1w.nii.gz \
--average 1 \
--template $TEMP/NAME_commontemp.nii.gz \
--satit

## Two time points
export MISSINGBL=/mnt/hdd/MT/HARMY/HARMY_WMH/regdata/y2/missing/BL
export MISSINGY2=/mnt/hdd/MT/HARMY/HARMY_WMH/regdata/y2/missing/Y2
export MISSINGY4Y5=/mnt/hdd/MT/HARMY/HARMY_WMH/regdata/y2/missing/Y4Y5
### BL Y2
for_each -nthreads 20 -info $MISSINGY4Y5/* : mri_robust_template \
--mov $BASELINE/NAME/anat/NAME_run-1_T1w.nii.gz \
$Y2/NAME/anat/NAME_run-1_T1w.nii.gz \
--average 1 \
--template $TEMP/NAME_commontemp.nii.gz \
--satit

### BL Y4Y5
for_each -nthreads 20 -info $MISSINGY4Y5/* : mri_robust_template \
--mov $BASELINE/NAME/anat/NAME_run-1_T1w.nii.gz \
$Y4Y5/NAME/anat/NAME_run-1_T1w.nii.gz \
--average 1 \
--template $TEMP/NAME_commontemp.nii.gz \
--satit

### Y2 Y4Y5
for_each -nthreads 15 -info $MISSINGBL/* : mri_robust_template \
--mov \
$Y2/NAME/anat/NAME_run-1_T1w.nii.gz \
$Y4Y5/NAME/anat/NAME_run-1_T1w.nii.gz \
--average 1 \
--template $TEMP/NAME_commontemp.nii.gz \
--satit

################################################################################
############################### Registration BL ################################
################################################################################
# T1 to common template [x]
export regBL=/mnt/hdd/MT/HARMY/HARMY_WMH/regdata/bl
export BASELINE=/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL
export regTEMP=/mnt/hdd/MT/HARMY/HARMY_WMH/regdata/common_template

for_each -nthreads 20 -info $BASELINE/* : mkdir -p $regBL/NAME

for_each -nthreads 20 -info $BASELINE/* : antsRegistrationSyN.sh \
-d 3 \
-f /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/common_template/NAME_commontemp.nii.gz \
-m $BASELINE/NAME/anat/NAME_run-1_T1w.nii.gz \
-o $regBL/NAME/T1_to_common_

# Error from above steps

for_each: [WARNING] For input "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/dataset_description.json" (returncode = 1):
Fixed image '/mnt/hdd/MT/HARMY/HARMY_WMH/regdata/common_template/dataset_description.json_commontemp.nii.gz' does not exist.  See usage: '/home/admin/Desktop/MRIapp/ants-2.5.0/bin/antsRegistrationSyN.sh -h 1'
for_each:
for_each: [WARNING] For input "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD005" (returncode = 1):
Fixed image '/mnt/hdd/MT/HARMY/HARMY_WMH/regdata/common_template/sub-HD005_commontemp.nii.gz' does not exist.  See usage: '/home/admin/Desktop/MRIapp/ants-2.5.0/bin/antsRegistrationSyN.sh -h 1'
for_each:
for_each: [WARNING] For input "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD026" (returncode = 1):
Fixed image '/mnt/hdd/MT/HARMY/HARMY_WMH/regdata/common_template/sub-HD026_commontemp.nii.gz' does not exist.  See usage: '/home/admin/Desktop/MRIapp/ants-2.5.0/bin/antsRegistrationSyN.sh -h 1'
for_each:
for_each: [WARNING] For input "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD040" (returncode = 1):
Fixed image '/mnt/hdd/MT/HARMY/HARMY_WMH/regdata/common_template/sub-HD040_commontemp.nii.gz' does not exist.  See usage: '/home/admin/Desktop/MRIapp/ants-2.5.0/bin/antsRegistrationSyN.sh -h 1'
for_each:
for_each: [WARNING] For input "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD056" (returncode = 1):
Fixed image '/mnt/hdd/MT/HARMY/HARMY_WMH/regdata/common_template/sub-HD056_commontemp.nii.gz' does not exist.  See usage: '/home/admin/Desktop/MRIapp/ants-2.5.0/bin/antsRegistrationSyN.sh -h 1'
for_each:
for_each: [WARNING] For input "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD088" (returncode = 1):
Fixed image '/mnt/hdd/MT/HARMY/HARMY_WMH/regdata/common_template/sub-HD088_commontemp.nii.gz' does not exist.  See usage: '/home/admin/Desktop/MRIapp/ants-2.5.0/bin/antsRegistrationSyN.sh -h 1'
for_each:
for_each: [WARNING] For input "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD100" (returncode = 1):
Fixed image '/mnt/hdd/MT/HARMY/HARMY_WMH/regdata/common_template/sub-HD100_commontemp.nii.gz' does not exist.  See usage: '/home/admin/Desktop/MRIapp/ants-2.5.0/bin/antsRegistrationSyN.sh -h 1'
for_each:
for_each: [WARNING] For input "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD203" (returncode = 1):
Fixed image '/mnt/hdd/MT/HARMY/HARMY_WMH/regdata/common_template/sub-HD203_commontemp.nii.gz' does not exist.  See usage: '/home/admin/Desktop/MRIapp/ants-2.5.0/bin/antsRegistrationSyN.sh -h 1'
for_each:
for_each: [WARNING] For input "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD309" (returncode = 1):

Fixed image '/mnt/hdd/MT/HARMY/HARMY_WMH/regdata/common_template/sub-HD309_commontemp.nii.gz' does not exist.  See usage: '/home/admin/Desktop/MRIapp/ants-2.5.0/bin/antsRegistrationSyN.sh -h 1'
####################################################################################################################

# FLAIR to T1 [x]
for_each -nthreads 20 -info $BASELINE/* : antsRegistrationSyN.sh \
-d 3 \
-f $BASELINE/NAME/anat/NAME_run-1_T1w.nii.gz \
-m $BASELINE/NAME/anat/NAME_run-1_FLAIR.nii.gz \
-o $regBL/NAME/FLAIR_to_T1_

#### ERRORS for F to T1
for_each: [WARNING] For input "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/dataset_description.json" (returncode = 1):
Fixed image '/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/dataset_description.json/anat/dataset_description.json_run-1_T1w.nii.gz' does not exist.  See usage: '/home/admin/Desktop/MRIapp/ants-2.5.0/bin/antsRegistrationSyN.sh -h 1'
for_each:
for_each: [WARNING] For input "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD056" (returncode = 1):
Moving image '/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD056/anat/sub-HD056_run-1_FLAIR.nii.gz' does not exist.  See usage: '/home/admin/Desktop/MRIapp/ants-2.5.0/bin/antsRegistrationSyN.sh -h 1'
for_each:
for_each: [WARNING] For input "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD088" (returncode = 1):
Moving image '/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD088/anat/sub-HD088_run-1_FLAIR.nii.gz' does not exist.  See usage: '/home/admin/Desktop/MRIapp/ants-2.5.0/bin/antsRegistrationSyN.sh -h 1'
for_each:
for_each: [WARNING] For input "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD203" (returncode = 1):
Moving image '/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD203/anat/sub-HD203_run-1_FLAIR.nii.gz' does not exist.  See usage: '/home/admin/Desktop/MRIapp/ants-2.5.0/bin/antsRegistrationSyN.sh -h 1'
for_each:
for_each: [WARNING] For input "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD309" (returncode = 1):
Moving image '/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD309/anat/sub-HD309_run-1_FLAIR.nii.gz' does not exist.  See usage: '/home/admin/Desktop/MRIapp/ants-2.5.0/bin/antsRegistrationSyN.sh -h 1'
for_each:
for_each: [WARNING] For input "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD314" (returncode = 1):
Moving image '/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD314/anat/sub-HD314_run-1_FLAIR.nii.gz' does not exist.  See usage: '/home/admin/Desktop/MRIapp/ants-2.5.0/bin/antsRegistrationSyN.sh -h 1'
for_each:
###

# FLAIR to T1 [x]
for_each -nthreads 20 -info $BASELINE/* : antsRegistrationSyN.sh \
-d 3 \
-f $BASELINE/NAME/anat/NAME_run-1_T1w.nii.gz \
-m $BASELINE/NAME/anat/NAME_run-1_FLAIR.nii.gz \
-o $regBL/NAME/FLAIR_to_T1_

#FLAIR-T1 to Common Space (Using T1-Common transform)[x]
for_each -nthreads 20 -info $BASELINE/* : antsApplyTransforms \
-d 3 \
-i $regBL/NAME/FLAIR_to_T1_Warped.nii.gz \
-r $regTEMP/NAME_commontemp.nii.gz \
-o $regBL/NAME/FLAIR_in_Common.nii.gz \
-t $regBL/NAME/T1_to_common_1Warp.nii.gz \
-t $regBL/NAME/T1_to_common_0GenericAffine.mat \
-n NearestNeighbor

or_each:
for_each: [WARNING] For input "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/dataset_description.json" (returncode = 1):
file /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/bl/dataset_description.json/FLAIR_to_T1_Warped.nii.gz does not exist .
file /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/common_template/dataset_description.json_commontemp.nii.gz does not exist .
Transform file does not exist: /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/bl/dataset_description.json/T1_to_common_0GenericAffine.mat
for_each:
for_each: [WARNING] For input "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD005" (returncode = 1):
file /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/common_template/sub-HD005_commontemp.nii.gz does not exist .
Transform file does not exist: /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/bl/sub-HD005/T1_to_common_0GenericAffine.mat
for_each:
for_each: [WARNING] For input "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD026" (returncode = 1):
file /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/common_template/sub-HD026_commontemp.nii.gz does not exist .
Transform file does not exist: /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/bl/sub-HD026/T1_to_common_0GenericAffine.mat
for_each:
for_each: [WARNING] For input "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD040" (returncode = 1):
file /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/common_template/sub-HD040_commontemp.nii.gz does not exist .
Transform file does not exist: /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/bl/sub-HD040/T1_to_common_0GenericAffine.mat
for_each:
for_each: [WARNING] For input "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD056" (returncode = 1):
file /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/bl/sub-HD056/FLAIR_to_T1_Warped.nii.gz does not exist .
file /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/common_template/sub-HD056_commontemp.nii.gz does not exist .
Transform file does not exist: /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/bl/sub-HD056/T1_to_common_0GenericAffine.mat
for_each:
for_each: [WARNING] For input "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD088" (returncode = 1):
file /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/bl/sub-HD088/FLAIR_to_T1_Warped.nii.gz does not exist .
file /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/common_template/sub-HD088_commontemp.nii.gz does not exist .
Transform file does not exist: /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/bl/sub-HD088/T1_to_common_0GenericAffine.mat
for_each:
for_each: [WARNING] For input "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD100" (returncode = 1):
file /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/common_template/sub-HD100_commontemp.nii.gz does not exist .
Transform file does not exist: /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/bl/sub-HD100/T1_to_common_0GenericAffine.mat
for_each:
for_each: [WARNING] For input "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD203" (returncode = 1):
file /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/bl/sub-HD203/FLAIR_to_T1_Warped.nii.gz does not exist .
file /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/common_template/sub-HD203_commontemp.nii.gz does not exist .
Transform file does not exist: /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/bl/sub-HD203/T1_to_common_0GenericAffine.mat
for_each:
for_each: [WARNING] For input "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD309" (returncode = 1):
file /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/bl/sub-HD309/FLAIR_to_T1_Warped.nii.gz does not exist .
file /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/common_template/sub-HD309_commontemp.nii.gz does not exist .
Transform file does not exist: /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/bl/sub-HD309/T1_to_common_0GenericAffine.mat
for_each:
for_each: [WARNING] For input "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL/sub-HD314" (returncode = 134):
file /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/bl/sub-HD314/FLAIR_to_T1_Warped.nii.gz does not exist .
terminate called after throwing an instance of 'itk::ExceptionObject'
what():  /home/runner/work/_temp/build/ITKv5/Modules/Core/Common/src/itkProcessObject.cxx:1339:
ITK ERROR: ResampleImageFilter(0x643d567c9c60): Input Primary is required but not set.
Aborted (core dumped)
for_each:

# WMH to common template  (apply T1-common transform) [x]
export BLLST=/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Cross_sectional/LSTAI_BL
for_each -nthreads 20 -info $BLLST/* : antsApplyTransforms \
-d 3 \
-i $BLLST/NAME/temp/sub-X_ses-Y_space-flair_seg-lst.nii.gz \
-r $regTEMP/NAME_commontemp.nii.gz \
-o /mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/bl/NAME/WMH_in_T1.nii.gz \
-t $regBL/NAME/T1_to_common_1Warp.nii.gz \
-t $regBL/NAME/T1_to_common_0GenericAffine.mat \
-n NearestNeighbor

#T1-Common to MNI [x]
for_each -nthreads 10 -info /mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/bl/* : antsRegistrationSyN.sh \
-d 3 \
-f /home/admin/Desktop/MRI/MNI152_T1_1mm.nii.gz \
-m $regBL/NAME/T1_to_common_Warped.nii.gz \
-o $regBL/NAME/T1_common_to_MNI_

#Apply T1-Common to MNI transform to FLAIR []
for_each -nthreads 10 -info $regBL/* : antsApplyTransforms \
-d 3 \
-i $regBL/NAME/FLAIR_to_T1_Warp.nii.gz \
-r /home/admin/Desktop/MRI/MNI152_T1_1mm.nii.gz \
-o $regBL/NAME/FLAIR_to_MNI_ \
-t $regBL/NAME/T1_Common_to_MNI_1Warp.nii.gz \
-t $regBL/NAME/T1_Common_to_MNI_0GenericAffine.mat \
-n NearestNeighbor

#Apply T1-Common to MNI transform to WMH []
for_each -nthreads 10 -info $regBL/* : antsApplyTransforms \
-d 3 \
-i $regBL/NAME/WMH_in_T1.nii.gz \
-r /home/admin/Desktop/MRI/MNI152_T1_1mm.nii.gz \
-o $regBL/NAME/WMH_in_MNI_ \
-t $regBL/NAME/T1_Common_to_MNI_1Warp.nii.gz \
-t $regBL/NAME/T1_Common_to_MNI_0GenericAffine.mat \
-n NearestNeighbor


################################################################################
############################### Registration Y2 ################################
################################################################################
# T1 to common template []
export regY2=/mnt/hdd/MT/HARMY/HARMY_WMH/regdata/y2
export Y2=/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_Y2
export regTEMP=/mnt/hdd/MT/HARMY/HARMY_WMH/regdata/common_template

for_each -nthreads 20 -info $Y2/* : mkdir -p $regY2/NAME


for_each -nthreads 20 -info $Y2/* : antsRegistrationSyN.sh \
-d 3 \
-f /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/common_template/NAME_commontemp.nii.gz \
-m $Y2/NAME/anat/NAME_run-1_T1w.nii.gz \
-o $regY2/NAME/T1_to_common_


# FLAIR to T1 []
for_each -nthreads 20 -info $Y2/* : antsRegistrationSyN.sh \
-d 3 \
-f $Y2/NAME/anat/NAME_run-1_T1w.nii.gz \
-m $Y2/NAME/anat/NAME_run-1_FLAIR.nii.gz \
-o $regY2/NAME/FLAIR_to_T1_

# FLAIR to T1 []
for_each -nthreads 20 -info $Y2/* : antsRegistrationSyN.sh \
-d 3 \
-f $Y2/NAME/anat/NAME_run-1_T1w.nii.gz \
-m $Y2/NAME/anat/NAME_run-1_FLAIR.nii.gz \
-o $regY2/NAME/FLAIR_to_T1_

#FLAIR-T1 to Common Space (Using T1-Common transform)[]
for_each -nthreads 20 -info $Y2/* : antsApplyTransforms \
-d 3 \
-i $regY2/NAME/FLAIR_to_T1_Warped.nii.gz \
-r $regTEMP/NAME_commontemp.nii.gz \
-o $regY2/NAME/FLAIR_in_Common.nii.gz \
-t $regY2/NAME/T1_to_common_1Warp.nii.gz \
-t $regY2/NAME/T1_to_common_0GenericAffine.mat \
-n NearestNeighbor

# WMH to common template  (apply T1-common transform) []
export Y2LST=/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Cross_sectional/LSTAI_Y2
for_each -nthreads 20 -info $Y2LST/* : antsApplyTransforms \
-d 3 \
-i $Y2LST/NAME/temp/sub-X_ses-Y_space-flair_seg-lst.nii.gz \
-r $regTEMP/NAME_commontemp.nii.gz \
-o /mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/y2/NAME/WMH_in_T1.nii.gz \
-t $regY2/NAME/T1_to_common_1Warp.nii.gz \
-t $regY2/NAME/T1_to_common_0GenericAffine.mat \
-n NearestNeighbor

#T1-Common to MNI []
for_each -nthreads 10 -info /mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/y2/* : antsRegistrationSyN.sh \
-d 3 \
-f /home/admin/Desktop/MRI/MNI152_T1_1mm.nii.gz \
-m $regY2/NAME/T1_to_common_Warped.nii.gz \
-o $regY2/NAME/T1_common_to_MNI_

#Apply T1-Common to MNI transform to FLAIR []
for_each -nthreads 10 -info $regY2/* : antsApplyTransforms \
-d 3 \
-i $regY2/NAME/FLAIR_to_T1_Warp.nii.gz \
-r /home/admin/Desktop/MRI/MNI152_T1_1mm.nii.gz \
-o $regY2/NAME/FLAIR_to_MNI_ \
-t $regY2/NAME/T1_Common_to_MNI_1Warp.nii.gz \
-t $regY2/NAME/T1_Common_to_MNI_0GenericAffine.mat \
-n NearestNeighbor

#Apply T1-Common to MNI transform to WMH []
for_each -nthreads 10 -info $regY2/* : antsApplyTransforms \
-d 3 \
-i $regY2/NAME/WMH_in_T1.nii.gz \
-r /home/admin/Desktop/MRI/MNI152_T1_1mm.nii.gz \
-o $regY2/NAME/WMH_in_MNI_ \
-t $regY2/NAME/T1_Common_to_MNI_1Warp.nii.gz \
-t $regY2/NAME/T1_Common_to_MNI_0GenericAffine.mat \
-n NearestNeighbor

################################################################################
############################### Registration Y4Y5 ##############################
################################################################################
# T1 to common template []
export regY4Y5=/mnt/hdd/MT/HARMY/HARMY_WMH/regdata/y4y5
export Y4Y5=/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_Y4Y5
export regTEMP=/mnt/hdd/MT/HARMY/HARMY_WMH/regdata/common_template

for_each -nthreads 20 -info $Y4Y5/* : mkdir -p $regY4Y5/NAME

for_each -nthreads 20 -info $Y4Y5/* : antsRegistrationSyN.sh \
-d 3 \
-f /mnt/hdd/MT/HARMY/HARMY_WMH/regdata/common_template/NAME_commontemp.nii.gz \
-m $Y4Y5/NAME/anat/NAME_run-1_T1w.nii.gz \
-o $regY4Y5/NAME/T1_to_common_


# FLAIR to T1 []
for_each -nthreads 20 -info $Y4Y5/* : antsRegistrationSyN.sh \
-d 3 \
-f $Y4Y5/NAME/anat/NAME_run-1_T1w.nii.gz \
-m $Y4Y5/NAME/anat/NAME_run-1_FLAIR.nii.gz \
-o $regY4Y5/NAME/FLAIR_to_T1_

# FLAIR to T1 []
for_each -nthreads 20 -info $Y4Y5/* : antsRegistrationSyN.sh \
-d 3 \
-f $Y4Y5/NAME/anat/NAME_run-1_T1w.nii.gz \
-m $Y4Y5/NAME/anat/NAME_run-1_FLAIR.nii.gz \
-o $regY4Y5/NAME/FLAIR_to_T1_

#FLAIR-T1 to Common Space (Using T1-Common transform)[]
for_each -nthreads 20 -info $Y4Y5/* : antsApplyTransforms \
-d 3 \
-i $regY4Y5/NAME/FLAIR_to_T1_Warped.nii.gz \
-r $regTEMP/NAME_commontemp.nii.gz \
-o $regY4Y5/NAME/FLAIR_in_Common.nii.gz \
-t $regY4Y5/NAME/T1_to_common_1Warp.nii.gz \
-t $regY4Y5/NAME/T1_to_common_0GenericAffine.mat \
-n NearestNeighbor

# WMH to common template  (apply T1-common transform) []
export Y4Y5LST=/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Cross_sectional/LSTAI_Y4Y5
for_each -nthreads 20 -info $Y4Y5LST/* : antsApplyTransforms \
-d 3 \
-i $Y4Y5LST/NAME/temp/sub-X_ses-Y_space-flair_seg-lst.nii.gz \
-r $regTEMP/NAME_commontemp.nii.gz \
-o /mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/y4y5/NAME/WMH_in_T1.nii.gz \
-t $regY4Y5/NAME/T1_to_common_1Warp.nii.gz \
-t $regY4Y5/NAME/T1_to_common_0GenericAffine.mat \
-n NearestNeighbor

#T1-Common to MNI []
for_each -nthreads 10 -info /mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/y4y5/* : antsRegistrationSyN.sh \
-d 3 \
-f /home/admin/Desktop/MRI/MNI152_T1_1mm.nii.gz \
-m $regY4Y5/NAME/T1_to_common_Warped.nii.gz \
-o $regY4Y5/NAME/T1_common_to_MNI_

#Apply T1-Common to MNI transform to FLAIR []
for_each -nthreads 10 -info $regY4Y5/* : antsApplyTransforms \
-d 3 \
-i $regY4Y5/NAME/FLAIR_to_T1_Warp.nii.gz \
-r /home/admin/Desktop/MRI/MNI152_T1_1mm.nii.gz \
-o $regY4Y5/NAME/FLAIR_to_MNI_ \
-t $regY4Y5/NAME/T1_Common_to_MNI_1Warp.nii.gz \
-t $regY4Y5/NAME/T1_Common_to_MNI_0GenericAffine.mat \
-n NearestNeighbor

#Apply T1-Common to MNI transform to WMH []
for_each -nthreads 10 -info $regY4Y5/* : antsApplyTransforms \
-d 3 \
-i $regY4Y5/NAME/WMH_in_T1.nii.gz \
-r /home/admin/Desktop/MRI/MNI152_T1_1mm.nii.gz \
-o $regY4Y5/NAME/WMH_in_MNI_ \
-t $regY4Y5/NAME/T1_Common_to_MNI_1Warp.nii.gz \
-t $regY4Y5/NAME/T1_Common_to_MNI_0GenericAffine.mat \
-n NearestNeighbor

##### Syncing folders to dropbox BL []

# Syncing folders to dropbox y2[]
# Find all FLAIR.nii.gz and seg-lst.nii.gz files and transfer them to Dropbox
# Set the base directory
BASE_DIR="/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Cross_sectional/LSTAI_Y2"

# Find all subject directories
find "$BASE_DIR" -type d -name "sub-HD*" | while read -r subject_dir; do
    # Get just the subject directory name
    subject_name=$(basename "$subject_dir")
    
    # Find the target files in this subject directory
    find "$subject_dir" -type f \( -iname "*space-flair_FLAIR.nii.gz" -o -iname "*space-flair_seg-lst.nii.gz" \) | while read -r file_path; do
        # Get the path relative to the subject directory
        rel_path=$(realpath --relative-to="$subject_dir" "$file_path")
        
        # Create the destination path
        dest_path="Dropbox:HARMY/WMH_LSTAI/Y2/$subject_name/$(dirname "$rel_path")"
        
        # Copy the file
        rclone copy -v "$file_path" "$dest_path"
    done
done


# Syncing folders to dropbox y4y5[]
# Find all FLAIR.nii.gz and seg-lst.nii.gz files and transfer them to Dropbox
# Set the base directory
BASE_DIR="/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Cross_sectional/LSTAI_Y4Y5"

# Find all subject directories
find "$BASE_DIR" -type d -name "sub-HD*" | while read -r subject_dir; do
    # Get just the subject directory name
    subject_name=$(basename "$subject_dir")
    
    # Find the target files in this subject directory
    find "$subject_dir" -type f \( -iname "*space-flair_FLAIR.nii.gz" -o -iname "*space-flair_seg-lst.nii.gz" \) | while read -r file_path; do
        # Get the path relative to the subject directory
        rel_path=$(realpath --relative-to="$subject_dir" "$file_path")
        
        # Create the destination path
        dest_path="Dropbox:HARMY/WMH_LSTAI/Y4Y5/$subject_name/$(dirname "$rel_path")"
        
        # Copy the file
        rclone copy -v "$file_path" "$dest_path"
    done
done



# files by LST-LPA
/mnt/hdd/MT/HARMY/HARMY_WMH/LST_LGA/Raw/BL/sub-HD092/anat/LST_lga_0.3_rmsub-HD092_run-1_FLAIR
/mnt/hdd/MT/HARMY/HARMY_WMH/LST_LGA/Raw/BL/sub-HD092/anat/LST_lga_rmsub-HD092_run-1_FLAIR.mat
/mnt/hdd/MT/HARMY/HARMY_WMH/LST_LGA/Raw/BL/sub-HD092/anat/ples_lga_0.3_rmsub-HD092_run-1_FLAIR.nii
/mnt/hdd/MT/HARMY/HARMY_WMH/LST_LGA/Raw/BL/sub-HD092/anat/report_LST_lga_0.3_rmsub-HD092_run-1_FLAIR.html
/mnt/hdd/MT/HARMY/HARMY_WMH/LST_LGA/Raw/BL/sub-HD092/anat/rmsub-HD092_run-1_FLAIR.nii
/mnt/hdd/MT/HARMY/HARMY_WMH/LST_LGA/Raw/BL/sub-HD092/anat/sub-HD092_run-1_FLAIR.json
/mnt/hdd/MT/HARMY/HARMY_WMH/LST_LGA/Raw/BL/sub-HD092/anat/sub-HD092_run-1_FLAIR.nii
/mnt/hdd/MT/HARMY/HARMY_WMH/LST_LGA/Raw/BL/sub-HD092/anat/sub-HD092_run-1_T1w.json
/mnt/hdd/MT/HARMY/HARMY_WMH/LST_LGA/Raw/BL/sub-HD092/anat/sub-HD092_run-1_T1w.nii