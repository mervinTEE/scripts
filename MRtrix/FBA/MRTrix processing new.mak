ROOTFOLDER="/home/admin/Desktop/MRI/MT/SPACE_DTI"
# THREADS=${3:-4}
THREADS=10
cd $ROOTFOLDER

########################### STEP 1 ###################################
#	        Computing (average) tissue response functions	   	     #
######################################################################

for_each -force -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix3/* : dwi2response dhollander IN/dwi/dwi_den_preproc_unbiased.mif IN/dwi/response_wm.txt IN/dwi/response_gm.txt IN/dwi/response_csf.txt

responsemean $ROOTFOLDER/derivatives/MRtrix3_response/*/dwi/response_wm.txt ../group_average_response_wm.txt
responsemean $ROOTFOLDER/derivatives/MRtrix3_response/*/dwi/response_gm.txt ../group_average_response_gm.txt
responsemean $ROOTFOLDER/derivatives/MRtrix3_response/*/dwi/response_csf.txt ../group_average_response_csf.txt

########################### STEP 2 ###################################
#                   Upsampling DW Images to 1.25mm isotropic        #
######################################################################

for_each -force -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix3/* : mrgrid IN/dwi/NAME_dwi_den_preproc_unbiased.mif regrid -voxel 1.25 IN/dwi/NAME_dwi_den_preproc_unbiased_upsampled.mif   

########################### STEP 3 ###################################
#                   Compute upsampled brain mask images             #
######################################################################

for_each -force -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix3/* : dwi2mask IN/dwi/NAME_dwi_den_preproc_unbiased_upsampled.mif IN/dwi/NAME_dwi_mask_upsampled.mif

########################## QC Step 1 #################################
#                   View Masks                                       #
######################################################################

mrview $ROOTFOLDER/derivatives/MRtrix3/sub-SPAC003/dwi/sub-SPAC003_dwi_mask_upsampled.mif

########################### STEP 4 ###################################
#                   Compute FOD images                               #
######################################################################

for_each -force -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix3/* : dwi2fod msmt_csd IN/dwi/NAME_dwi_den_preproc_unbiased_upsampled.mif /home/admin/Desktop/MRI/MT/SPACE_DTI/derivatives/MRtrix3_group/group_average_response_wm.txt IN/dwi/NAME_wmfod.mif /home/admin/Desktop/MRI/MT/SPACE_DTI/derivatives/MRtrix3_group/group_average_response_gm.txt IN/dwi/NAME_gm.mif  /home/admin/Desktop/MRI/MT/SPACE_DTI/derivatives/MRtrix3_group/group_average_response_csf.txt IN/dwi/NAME_csf.mif -mask IN/dwi/NAME_dwi_mask_upsampled.mif

########################### Step 5 ###################################
#                   Normalise FOD images                             #
######################################################################

for_each -force -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix/* : mtnormalise IN/dwi/wmfod.mif IN/dwi/wmfod_norm.mif IN/dwi/gm.mif IN/dwi/gm_norm.mif IN/dwi/csf.mif IN/dwi/csf_norm.mif -mask IN/dwi/dwi_mask_upsampled.mif

########################### Step 6 ###################################
#                   Create FOD template                              #
######################################################################
mkdir -p $ROOTFOLDER/derivatives/MRtrix3_group/template/fod_input
mkdir $ROOTFOLDER/derivatives/MRtrix3_group/template/mask_input

for_each -force -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix/* : ln -s IN/dwi/wmfod_norm.mif $ROOTFOLDER/derivatives/MRtrix3_group/template/fod_input/PRE.mif

for_each -force -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix/* : ln -s IN/dwi/dwi_mask_upsampled.mif $ROOTFOLDER/derivatives/MRtrix3_group/template/mask_input/PRE.mif

population_template $ROOTFOLDER/derivatives/MRtrix3_group/template/fod_input -mask_dir $ROOTFOLDER/derivatives/MRtrix3_group/template/mask_input $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template.mif -voxel_size 1.25

########################### QC Step 2 ###################################
#                     View FOD template                                 #
#########################################################################
mrview $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template.mif

############################## Step 7 ###################################
#                    Register FOD images to FOD template                #
#########################################################################

mrconvert $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template.mif $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template_bad_strides.nii.gz
mrview $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template_bad_strides.nii.gz


mrconvert $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template_bad_strides.nii.gz $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template.nii.gz -strides -1,2,3,4

### chekc if this step can cut the two steps above
mrconvert $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template.mif $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template.nii.gz -strides -1,2,3,4
###

mrview $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template.nii.gz

# -coord 3 0: 3 to extract 4th axis, 0 to extract the first volume of the 4D image
mrconvert $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template.nii.gz $ROOTFOLDER/derivatives/MRtrix3_group/template/l0image.nii.gz -coord 3 0
mrview $ROOTFOLDER/derivatives/MRtrix3_group/template/l0image.nii.gz

# remove nan for flirt
fslmaths $ROOTFOLDER/derivatives/MRtrix3_group/template/l0image.nii.gz -nan $ROOTFOLDER/derivatives/MRtrix3_group/template/l0image_no_nan.nii.gz

flirt -ref $ROOTFOLDER/derivatives/MRtrix3_group/template/MNI_FA_template.nii.gz -in $ROOTFOLDER/derivatives/MRtrix3_group/template/l0image_no_nan.nii.gz -out $ROOTFOLDER/derivatives/MRtrix3_group/template/l0image_MNI.nii.gz -omat $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template_2_MNI.mat -dof 12
mrview $ROOTFOLDER/derivatives/MRtrix3_group/template/l0image_MNI.nii.gz

transformconvert $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template_2_MNI.mat $ROOTFOLDER/derivatives/MRtrix3_group/template/l0image_no_nan.nii.gz $ROOTFOLDER/derivatives/MRtrix3_group/template/MNI_FA_template.nii.gz flirt_import $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template_2_MNI.txt

#### Transform the FOD template to MNI space
mrtransform -reorient_fod 1 $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template.nii.gz -linear $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template_2_MNI.txt -template $ROOTFOLDER/derivatives/MRtrix3_group/template/MNI_FA_template.nii.gz $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template_MNI_reorient.nii.gz

mrconvert $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template_MNI_reorient.nii.gz $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template_MNI_reorient.mif

#### Generate subject to template warps using the study specific population template.
 
for_each -force -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix3/* : mrregister IN/dwi/NAME_wmfod_norm.mif -mask1 IN/dwi/NAME_dwi_mask_upsampled.mif $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template_MNI_reorient.mif -nl_warp IN/dwi/NAME_subject2template_warp.mif IN/dwi/NAME_template2subject_warp.mif

############################## Step 8 ###################################
#          Register brain masks for each subject to MNI space           #
#########################################################################

# transform brain mask to MNI space
for_each -force -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix3/* : mrtransform IN/dwi/NAME_dwi_mask_upsampled.mif -warp IN/dwi/NAME_subject2template_warp.mif -interp nearest -datatype bit IN/dwi/dwi_mask_in_template_space.mif

# average masks to obtain a study specific template mask
mrmath $ROOTFOLDER/derivatives/MRtrix3/*/dwi/dwi_mask_in_template_space.mif min $ROOTFOLDER/derivatives/MRtrix3_group/template/template_mask.mif -datatype bit

mrinfo $ROOTFOLDER/derivatives/MRtrix3_group/template/template_mask.mif
mrinfo $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template_MNI_reorient.mif

############################## Step 9 ###################################
#       Compute a white matter template analysis fixel mask             #
#########################################################################
# Resampling to match the dimensions of wmfod_template
mrgrid $ROOTFOLDER/derivatives/MRtrix3_group/template/template_mask.mif regrid -template $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template.mif $ROOTFOLDER/derivatives/MRtrix3_group/template/template_mask_resampled.mif

# Compute a white matter template analysis fixel mask
fod2fixel -mask $ROOTFOLDER/derivatives/MRtrix3_group/template/template_mask_resampled.mif -fmls_peak_value 0.06 $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template.mif $ROOTFOLDER/derivatives/MRtrix3_group/template/fixel_mask

fod2fixel -

# Transform masks for each subject to template space and average them to obtain a study specific template mask.
 
foreach * : mrtransform IN/dwi_mask_upsampled.mif -warp IN/subject2template_warp.mif -interp nearest -datatype bit IN/dwi_mask_in_template_space.mif
mrmath */dwi_mask_in_template_space.mif min ../template/template_mask.mif -datatype bit









