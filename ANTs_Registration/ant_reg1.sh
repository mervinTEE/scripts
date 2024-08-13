#!/bin/bash

: <<COMMENTBLOCK
This is Aneta's approach using the old ants
Call ANTS to do normalization.
Assume we are in the directory with the images we need
Pass in 2 arguments:
1) a T1 anatomical extracted brain image (result of optibet)
2) a lesion mask (1=lesion; 0=non-lesion)
e.g. ant_reg2.sh sub-001_T1w_brain.nii.gz sub-001_LesionSmooth.nii.gz
Assume we are in a subject directory and the images we want to work with are in this directory.
We get the sub variable from the directory name.

COMMENTBLOCK

# define some variables
t1brain=$1
lesionmask=$2
template=/usr/local/fsl/data/standard/MNI152_T1_2mm_brain.nii.gz
sub=`basename ${PWD}`
lesionmask_inv=${sub}_T1w_lesioninv.nii.gz
t1=${sub}_T1w.nii.gz
t1brain_masked=${sub}_T1w_brain_masked.nii.gz

# The output file comes first in the ImageMath command,
# So this command creates the inverse (negative) of the lesionmask
if [ ! -e ${lesionmask_inv} ]; then
ImageMath 3 ${lesionmask_inv} Neg ${lesionmask}
fi

if [ ! -e ${t1brain_masked} ]; then
# Multiply the T1w brain by the inverse mask
MultiplyImages 3 ${t1brain} ${lesionmask_inv} ${t1brain_masked}
fi
#
ANTS 3 -m MI[${template}, ${t1brain_masked},1,32] -o ${sub}_T1w_brain_MNI_ants -r Gauss[2,0] -t SyN[0.5] -i 30x99x11 --use-Histogram-Matching

# register the lesion mask using nearest neighbour interpolation
if [ ! -e {sub}_MNI_lesion.nii.gz ]; then
WarpImageMultiTransform 3 ${lesionmask} ${sub}_MNI_lesion.nii.gz -R ${template} ${sub}_T1w_brain_MNI_antsWarp.nii.gz ${sub}_T1w_brain_MNI_antsAffine.txt --use-NN
fi

#register the brain only
if [ ! -e {sub}_MNI_brain.nii.gz ]; then
WarpImageMultiTransform 3 ${t1brain} ${sub}_MNI_brain.nii.gz -R ${template} ${sub}_T1w_brain_MNI_antsWarp.nii.gz ${sub}_T1w_brain_MNI_antsAffine.txt
fi

# register the whole head
if [ ! -e {sub}_MNI.nii.gz ]; then
WarpImageMultiTransform 3 ${t1} ${sub}_MNI.nii.gz -R ${template} ${sub}_T1w_brain_MNI_antsWarp.nii.gz ${sub}_T1w_brain_MNI_antsAffine.txt
fi

# register the brain mask using nearest neighbour interpolation
if [ ! -e ${sub}_MNI_brain_mask.nii.gz ]; then
WarpImageMultiTransform 3 ${t1_brain_mask} ${sub}_MNI_brain_mask.nii.gz -R ${template} ${sub}_T1w_brain_MNI_antsWarp.nii.gz ${sub}_T1w_brain_MNI_antsAffine.txt --use-NN
fi
