ROOTFOLDER="/Users/owner/Desktop/dcm2bids-tutorial/bids_project"
# THREADS=${3:-4}
THREADS=1
cd $ROOTFOLDER

########################### STEP 1 ###################################
#	        Computing (average) tissue response functions	   	     #
######################################################################

for_each -force -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix/* : dwi2response dhollander IN/dwi/dwi_den_preproc_unbiased.mif IN/dwi/response_wm.txt IN/dwi/response_gm.txt IN/dwi/response_csf.txt

responsemean $ROOTFOLDER/derivatives/MRtrix/*/dwi/response_wm.txt ../group_average_response_wm.txt
responsemean $ROOTFOLDER/derivatives/MRtrix//*/dwi/response_gm.txt ../group_average_response_gm.txt
responsemean $ROOTFOLDER/derivatives/MRtrix/*/dwi/response_csf.txt ../group_average_response_csf.txt

########################### STEP 2 ###################################
#                   Upsampling DW Images to 1.25mm isotropic        #
######################################################################

for_each -force -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix/* : mrgrid IN/dwi/dwi_den_preproc_unbiased.mif regrid -voxel 1.25 IN/dwi/dwi_den_preproc_unbiased_upsampled.mif   

########################### STEP 3 ###################################
#                   Compute upsampled brain mask images             #
######################################################################

for_each -force -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix/* : dwi2mask IN/dwi/dwi_den_preproc_unbiased_upsampled.mif IN/dwi/dwi_mask_upsampled.mif

########################## QC Step 1 #################################
#                   View Masks                                       #
######################################################################

mrview $ROOTFOLDER/derivatives/MRtrix/sub-SPAC003/dwi/dwi_mask_upsampled.mif

########################### STEP 4 ###################################
#                   Compute FOD images                               #
######################################################################

for_each -force -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix/* : dwi2fod msmt_csd IN/dwi/dwi_den_preproc_unbiased_upsampled.mif ../group_average_response_wm.txt IN/dwi/wmfod.mif ../group_average_response_gm.txt IN/dwi/gm.mif  ../group_average_response_csf.txt IN/dwi/csf.mif -mask IN/dwi/dwi_mask_upsampled.mif

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
mrview $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template.nii.gz

mrconvert $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template.nii.gz $ROOTFOLDER/derivatives/MRtrix3_group/template/l0image.nii.gz -coord 3 0
mrview $ROOTFOLDER/derivatives/MRtrix3_group/template/l0image.nii.gz

# remove nan for flirt
fslmaths $ROOTFOLDER/derivatives/MRtrix3_group/template/l0image.nii.gz -nan $ROOTFOLDER/derivatives/MRtrix3_group/template/l0image_no_nan.nii.gz

flirt -ref $ROOTFOLDER/derivatives/MRtrix3_group/template/MNI_FA_template.nii.gz -in $ROOTFOLDER/derivatives/MRtrix3_group/template/l0image_no_nan.nii.gz -out $ROOTFOLDER/derivatives/MRtrix3_group/template/l0image_MNI.nii.gz -omat $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template_2_MNI.mat -dof 12
mrview $ROOTFOLDER/derivatives/MRtrix3_group/template/l0image_MNI.nii.gz

transformconvert $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template_2_MNI.mat $ROOTFOLDER/derivatives/MRtrix3_group/template/l0image_no_nan.nii.gz $ROOTFOLDER/derivatives/MRtrix3_group/template/MNI_FA_template.nii.gz flirt_import $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template_2_MNI.txt

#### Do I reorient_fod?
mrtransform -reorient_fod 1 $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template.nii.gz -linear $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template_2_MNI.txt -template $ROOTFOLDER/derivatives/MRtrix3_group/template/MNI_FA_template.nii.gz $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template_MNI_reorient.nii.gz

mrview $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template_MNI.nii.gz
mrview $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template_MNI_reorient.nii.gz

mrconvert $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template_MNI.nii.gz $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template_MNI.mif

#### Generate subject to template warps using the study specific population template.
 
for_each -force -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix/* : mrregister IN/dwi/wmfod_norm.mif -mask1 IN/dwi/dwi_mask_upsampled.mif $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template_MNI.mif -nl_warp IN/dwi/subject2template_warp.mif IN/dwi/template2subject_warp.mif

############################## Step 8 ###################################
#          Register brain masks for each subject to MNI space           #
#########################################################################

# transform brain mask to MNI space
for_each -force -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix/* : mrtransform IN/dwi/dwi_mask_upsampled.mif -warp IN/dwi/subject2template_warp.mif -interp nearest -datatype bit IN/dwi/dwi_mask_in_template_space.mif

# average masks to obtain a study specific template mask
mrmath */dwi/dwi_mask_in_template_space.mif min $ROOTFOLDER/derivatives/MRtrix3_group/template/template_mask.mif -datatype bit

############################## Step 9 ###################################
#       Compute a white matter template analysis fixel mask             #
#########################################################################

# Compute a white matter template analysis fixel mask
fod2fixel -mask $ROOTFOLDER/derivatives/MRtrix3_group/template/template_mask.mif -fmls_peak_value 0.06 $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template.mif $ROOTFOLDER/derivatives/MRtrix3_group/template/fixel_mask


# Transform masks for each subject to template space and average them to obtain a study specific template mask.
 
foreach * : mrtransform IN/dwi_mask_upsampled.mif -warp IN/subject2template_warp.mif -interp nearest -datatype bit IN/dwi_mask_in_template_space.mif
mrmath */dwi_mask_in_template_space.mif min ../template/template_mask.mif -datatype bit










Register subjs FOD images to FOD templates
for_each $ROOTFOLDER/derivatives/MRtrix3/* : mrregister -force -nthreads ${THREADS} IN/dwi/NAME_wmfod_norm.mif -mask1 IN/dwi/NAME_dwi_mask_upsampled.mif $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template.mif -nl_warp IN/dwi/NAME_subj2template_warp.mif IN/dwi/NAME_template2subj_warp.mif

ls ${FSLDIR}/data/standard