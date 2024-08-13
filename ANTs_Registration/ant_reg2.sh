#!/bin/bash

: <<COMMENTBLOCK
This should be the more modern approach.
Assume we are in the directory with the images we need
Pass in 2 arguments:
1) a T1 anatomical extracted brain image (result of optibet)
2) a lesion mask (1=lesion; 0=non-lesion)
e.g. ant_reg.sh sub-001_T1w_brain.nii.gz lesionmask.nii.gz

Call antsRegistrationSyn.sh to do normalization following
https://github.com/stnava/BasicBrainMapping/blob/master/bbm.sh

Use antsApplyTransforms to apply the affine and warp files and create the output files.
COMMENTBLOCK

# define some variables
t1brain=$1
lesionmask=$2
template=/usr/local/fsl/data/standard/MNI152_T1_2mm_brain.nii.gz
sub=`basename ${PWD}`
t1=${sub}_T1w.nii.gz
# This brain mask is the result of the optibet tool
t1_brain_mask=${sub}_brain_mask.nii.gz
lesionmask_inv=${sub}_T1w_lesioninv.nii.gz


# The output file comes first in the command,
# So this command creates the inverse (negative) of the lesionmask
if [ ! -e ${lesionmask_inv} ]; then
ImageMath 3 ${lesionmask_inv} Neg ${lesionmask}
fi

if [ ! -e ${sub}_T1w_MNIWarped.nii.gz ]; then
# The resulting file *MNIWarped* is the subject file in standard space
antsRegistrationSyN.sh -d 3 -f ${template} -m ${t1brain} -o ${sub}_T1w_MNI -j 1 -x ${lesionmask_inv}
fi

# Apply registrations
# Note the -t in front of each of them.  The order of application is LIFO, so affine, and then warp.

# Apply the affine transform and inverse warp to the lesion file.
# Use nearest neighbour interpolation because this is a mask
if [ ! -e {sub}_MNI_lesion.nii.gz ]; then
antsApplyTransforms -d 3 -i ${lesionmask} -r ${template} -o ${sub}_MNI_lesion.nii.gz -n NearestNeighbor -t ${sub}_T1w_MNI1InverseWarp.nii.gz -t ${sub}_T1w_MNI0GenericAffine.mat -v
fi

# Apply the affine transform and inverse warp to the original brain file
if [ ! -e {sub}_MNI_brain.nii.gz ]; then
antsApplyTransforms -d 3 -i ${t1brain} -r ${template} -o ${sub}_MNI_brain.nii.gz -t ${sub}_T1w_MNI1InverseWarp.nii.gz -t ${sub}_T1w_MNI0GenericAffine.mat   -v
fi

# Apply the affine transform and inverse warp to the original whole head file
if [ ! -e ${sub}_MNI.nii.gz ]; then
antsApplyTransforms -d 3 -i ${t1} -r ${template} -o ${sub}_MNI.nii.gz -t ${sub}_T1w_MNI1InverseWarp.nii.gz -t ${sub}_T1w_MNI0GenericAffine.mat  -v
fi

# Apply the affine transform and inverse warp to the brain mask file.
# Use nearest neighbour interpolation because this is a mask
if [ ! -e ${sub}_MNI_brain_mask.nii.gz ]; then
antsApplyTransforms -d 3 -i ${t1_brain_mask} -r ${template} -o ${sub}_MNI_brain_mask.nii.gz -n NearestNeighbor -t ${sub}_T1w_MNI1InverseWarp.nii.gz -t ${sub}_T1w_MNI0GenericAffine.mat  -v
fi
