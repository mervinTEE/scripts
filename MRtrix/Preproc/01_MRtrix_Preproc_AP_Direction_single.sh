#!/bin/bash

# Written by Andrew Jahn, University of Michigan, 02.25.2019
# Updated 07.10.2020 to incorporate changes from MRtrix version 3.0.1
# Based on Marlene Tahedl's BATMAN tutorial (http://www.miccai.org/edu/finalists/BATMAN_trimmed_tutorial.pdf)
# The main difference between this script and the other one in this repository, is that this script assumes that your diffusion images were acquired with AP phase encoding
# Thanks to John Plass and Bennet Fauber for useful comments

display_usage() {
    echo "$(basename $0) [rootfolder path] [subid] [no. of threads]"
    echo "This script uses MRtrix to analyze diffusion data. It requires 7 arguments:
		1) The rootfolder path (e.g. /home/admin/Desktop/MRI/MT/5DTI/rawdata);
    2) subid matching rawdata subject folder (for single subject), use '{}' when processing in parallel"
}

if [ $# -le 1 ]
then
    display_usage
    exit 1
fi

#RAW_DWI=$1
#REV_PHASE=$2
#AP_BVEC=$3
#AP_BVAL=$4
#PA_BVEC=$5
#PA_BVAL=$6
#ANAT=$7
ROOTFOLDER=$1
SUB=$2
THREADS=${3:-4}
#ROOTFOLDER=~/Desktop/MRI/MT/1DTI
#SUB=sub-SPAC001
#THREADS=10

########################### STEP 1 ###################################
#	        Convert data to .mif format and denoise	   	     #
######################################################################

# Also consider doing Gibbs denoising (using mrdegibbs). Check your diffusion data for ringing artifacts before deciding whether to use it
mkdir -p $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi $ROOTFOLDER/derivatives/MRtrix3/${SUB}/anat $ROOTFOLDER/derivatives/MRtrix3/${SUB}/fmap $ROOTFOLDER/tmp
mrconvert -force $ROOTFOLDER/rawdata/${SUB}/dwi/${SUB}_dwi.nii.gz $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_raw_dwi.mif -fslgrad $ROOTFOLDER/rawdata/${SUB}/dwi/${SUB}_dwi.bvec $ROOTFOLDER/rawdata/${SUB}/dwi/${SUB}_dwi.bval
dwidenoise -force -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_raw_dwi.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_dwi_den.mif -noise $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_noise.mif

# Extract the b0 images from the diffusion data acquired in the PA direction
dwiextract -force $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_raw_dwi.mif - -bzero | mrmath - mean $ROOTFOLDER/derivatives/MRtrix3/${SUB}/fmap/${SUB}_mean_b0_PA.mif -axis 3


# Extracts the b0 images for diffusion data acquired in the AP direction
# The term "fieldmap" is taken from the output from Michigan's fMRI Lab; it is not an actual fieldmap, but rather a collection of b0 images with both PA and AP phase encoding
# For the PA_BVEC and PA_BVAL files, they should be in the follwing format (assuming you extract only one volume):
# AP_BVEC: 0 0 0
# AP_BVAL: 0
mrconvert -force $ROOTFOLDER/rawdata/${SUB}/fmap/${SUB}_dir-AP_B0.nii.gz $ROOTFOLDER/derivatives/MRtrix3/${SUB}/fmap/${SUB}_AP.mif # If the PA map contains only 1 image, you will need to add the option "-coord 3 0"
mrconvert -force $ROOTFOLDER/derivatives/MRtrix3/${SUB}/fmap/${SUB}_AP.mif -fslgrad /$ROOTFOLDER/rawdata/${SUB}/fmap/${SUB}_dir-AP_B0.bvec $ROOTFOLDER/rawdata/${SUB}/fmap/${SUB}_dir-AP_B0.bval - | mrmath - mean $ROOTFOLDER/derivatives/MRtrix3/${SUB}/fmap/${SUB}_mean_b0_AP.mif -axis 3

# Concatenates the b0 images from AP and PA directions to create a paired b0 image
mrcat -force $ROOTFOLDER/derivatives/MRtrix3/${SUB}/fmap/${SUB}_mean_b0_PA.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/fmap/${SUB}_mean_b0_AP.mif -axis 3 $ROOTFOLDER/derivatives/MRtrix3/${SUB}/fmap/${SUB}_b0_pair.mif

# Removes last volume from DWI image (check if this is necessary, not for all DWI)
mrconvert -force $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_dwi_den.mif -coord 3 0:123 $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_dwi_den_dir124.mif

# Runs the dwipreproc command, which is a wrapper for eddy and topup. This step takes about 2 hours on an iMac desktop with 8 cores
# --slm=none for single/multi-shell, linear for single-shell
dwifslpreproc -force -nthreads ${THREADS}  -scratch $ROOTFOLDER/tmp/${SUB} $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_dwi_den_dir124.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_dwi_den_preproc.mif -nocleanup -pe_dir PA -rpe_pair -se_epi $ROOTFOLDER/derivatives/MRtrix3/${SUB}/fmap/${SUB}_b0_pair.mif -eddy_options " --slm=none --data_is_shelled"

# Performs bias field correction. Needs ANTs to be installed in order to use the "ants" option (use "fsl" otherwise)
dwibiascorrect -force -nthreads ${THREADS} -scratch $ROOTFOLDER/tmp/${SUB} ants $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_dwi_den_preproc.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_dwi_den_preproc_unbiased.mif -bias $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_bias.mif

# Create a mask for future processing steps
dwi2mask -force -scratch $ROOTFOLDER/tmp/${SUB} $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_dwi_den_preproc_unbiased.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_mask.mif


########################### STEP 2 ###################################
#             Basis function for each tissue type                    #
######################################################################

# Create a basis function from the subject's DWI data. The "dhollander" function is best used for multi-shell acquisitions; it will estimate different basis functions for each tissue type. For single-shell acquisition, use the "tournier" function instead
dwi2response -force -nthreads ${THREADS} -scratch $ROOTFOLDER/tmp/${SUB} dhollander $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_dwi_den_preproc_unbiased.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_wm.txt $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_gm.txt $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_csf.txt -voxels $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_voxels.mif

# Performs multishell-multitissue constrained spherical deconvolution, using the basis functions estimated above
dwi2fod -force -nthreads ${THREADS} msmt_csd $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_dwi_den_preproc_unbiased.mif -mask $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_mask.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_wm.txt $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_wmfod.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_gm.txt $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_gmfod.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_csf.txt $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_csffod.mif

# Creates an image of the fiber orientation densities overlaid onto the estimated tissues (Blue=WM; Green=GM; Red=CSF)
# You should see FOD's mostly within the white matter. These can be viewed later with the command "mrview vf.mif -odf.load_sh wmfod.mif"
mrconvert -force -nthreads ${THREADS} -coord 3 0 $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_wmfod.mif - | mrcat $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_csffod.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_gmfod.mif - $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_vf.mif

# Now normalize the FODs to enable comparison between subjects
mtnormalise -force -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_wmfod.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_wmfod_norm.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_gmfod.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_gmfod_norm.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_csffod.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_csffod_norm.mif -mask $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_mask.mif


########################### STEP 3 ###################################
#            Create a GM/WM boundary for seed analysis               #
######################################################################

# Convert the anatomical image to .mif format, and then extract all five tissue catagories (1=GM; 2=Subcortical GM; 3=WM; 4=CSF; 5=Pathological tissue)
mrconvert -force $ROOTFOLDER/rawdata/${SUB}/anat/${SUB}_T1w.nii.gz $ROOTFOLDER/derivatives/MRtrix3/${SUB}/anat/${SUB}_anat.mif
5ttgen -force fsl $ROOTFOLDER/derivatives/MRtrix3/${SUB}/anat/${SUB}_anat.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/anat/${SUB}_5tt_nocoreg.mif

# The following series of commands will take the average of the b0 images (which have the best contrast), convert them and the 5tt image to NIFTI format, and use it for coregistration.
dwiextract -force $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_dwi_den_preproc_unbiased.mif - -bzero | mrmath - mean $ROOTFOLDER/derivatives/MRtrix3/${SUB}/fmap/${SUB}_mean_b0_processed.mif -axis 3
mrconvert -force $ROOTFOLDER/derivatives/MRtrix3/${SUB}/fmap/${SUB}_mean_b0_processed.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/fmap/${SUB}_mean_b0_processed.nii.gz
mrconvert -force $ROOTFOLDER/derivatives/MRtrix3/${SUB}/anat/${SUB}_5tt_nocoreg.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/anat/${SUB}_5tt_nocoreg.nii.gz

# Uses FSL commands fslroi and flirt to create a transformation matrix for regisitration between the tissue map and the b0 images
fslroi $ROOTFOLDER/derivatives/MRtrix3/${SUB}/anat/${SUB}_5tt_nocoreg.nii.gz $ROOTFOLDER/derivatives/MRtrix3/${SUB}/anat/${SUB}_5tt_vol0.nii.gz 0 1 #Extract the first volume of the 5tt dataset (since flirt can only use 3D images, not 4D images)
flirt -in $ROOTFOLDER/derivatives/MRtrix3/${SUB}/fmap/${SUB}_mean_b0_processed.nii.gz -ref $ROOTFOLDER/derivatives/MRtrix3/${SUB}/anat/${SUB}_5tt_vol0.nii.gz -interp nearestneighbour -dof 6 -omat $ROOTFOLDER/derivatives/MRtrix3/${SUB}/anat/${SUB}_diff2struct_fsl.mat

transformconvert -force $ROOTFOLDER/derivatives/MRtrix3/${SUB}/anat/${SUB}_diff2struct_fsl.mat $ROOTFOLDER/derivatives/MRtrix3/${SUB}/fmap/${SUB}_mean_b0_processed.nii.gz $ROOTFOLDER/derivatives/MRtrix3/${SUB}/anat/${SUB}_5tt_nocoreg.nii.gz flirt_import $ROOTFOLDER/derivatives/MRtrix3/${SUB}/anat/${SUB}_diff2struct_mrtrix.txt
mrtransform -force $ROOTFOLDER/derivatives/MRtrix3/${SUB}/anat/${SUB}_5tt_nocoreg.mif -linear $ROOTFOLDER/derivatives/MRtrix3/${SUB}/anat/${SUB}_diff2struct_mrtrix.txt -inverse $ROOTFOLDER/derivatives/MRtrix3/${SUB}/anat/${SUB}_5tt_coreg.mif

#Create a seed region along the GM/WM boundary
5tt2gmwmi -force $ROOTFOLDER/derivatives/MRtrix3/${SUB}/anat/${SUB}_5tt_coreg.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/anat/${SUB}_gmwmSeed_coreg.mif

########################### STEP 4 ###################################
#                 Run the streamline analysis                        #
######################################################################

# Create streamlines
# Note that the "right" number of streamlines is still up for debate. Last I read from the MRtrix documentation,
# They recommend about 100 million tracks. Here I use 10 million, if only to save time. Read their papers and then make a decision
tckgen -force -act $ROOTFOLDER/derivatives/MRtrix3/${SUB}/anat/${SUB}_5tt_coreg.mif -backtrack -seed_gmwmi $ROOTFOLDER/derivatives/MRtrix3/${SUB}/anat/${SUB}_gmwmSeed_coreg.mif -nthreads ${THREADS} -maxlength 250 -cutoff 0.06 -select 10000000 $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_wmfod_norm.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_tracks_10M.tck

# Extract a subset of tracks (here, 200 thousand) for ease of visualization
tckedit -force $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_tracks_10M.tck -number 200k $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_smallerTracks_200k.tck

# Reduce the number of streamlines with tcksift
tcksift2 -force -act $ROOTFOLDER/derivatives/MRtrix3/${SUB}/anat/${SUB}_5tt_coreg.mif -out_mu $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_sift_mu.txt -out_coeffs $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_ift_coeffs.txt -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_tracks_10M.tck $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_wmfod_norm.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_sift_1M.txt
