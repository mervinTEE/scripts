ROOTFOLDER=/home/admin/Desktop/MRI/MT/SPACE_DTI
SUB=sub-SPAC001
THREADS=20

########################### STEP 1 ###################################
#             Basis function for each tissue type                    #
######################################################################
# Create a basis function from the subject's DWI data. The "dhollander" function is best used for multi-shell acquisitions; it will estimate different basis functions for each tissue type. For single-shell acquisition, use the "tournier" function instead
dwi2response -force -nthreads ${THREADS} -scratch $ROOTFOLDER/tmp/${SUB} dhollander $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_dwi_den_preproc_unbiased.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_wm.txt $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_gm.txt $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_csf.txt -voxels $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_voxels.mif

# Creating group average response files
mkdir -p $ROOTFOLDER/derivatives/MRtrix3_group/
responsemean $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_wm.txt $ROOTFOLDER/derivatives/MRtrix3_group/group_average_response_wm.txt
responsemean $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_gm.txt $ROOTFOLDER/derivatives/MRtrix3_group/group_average_response_gm.txt
responsemean $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_csf.txt $ROOTFOLDER/derivatives/MRtrix3_group/group_average_response_csf.txt

########################### STEP 2 ###################################
#                       Upsampling DW Images                         #
######################################################################
#Single processing
mrgrid  -force -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_dwi_den_preproc_unbiased.mif regrid -vox 1.25 $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_dwi_den_preproc_unbiased_upsampled.mif

#Loop processing
for_each $ROOTFOLDER/derivatives/MRtrix3/* : mrgrid -force -nthreads ${THREADS} IN/dwi/NAME_dwi_den_preproc_unbiased.mif regrid -vox 1.25 IN/dwi/NAME_dwi_den_preproc_unbiased_upsampled.mif

########################### STEP 3  ##################################
#                       Compute Unsampled brain mask                 #
######################################################################
#Single processing
dwi2mask -force -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_dwi_den_preproc_unbiased_upsampled.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_dwi_mask_upsampled.mif
#Loop processing
for_each $ROOTFOLDER/derivatives/MRtrix3/* : dwi2mask -force -nthreads ${THREADS} IN/dwi/NAME_dwi_den_preproc_unbiased_upsampled.mif IN/dwi/NAME_dwi_mask_upsampled.mif

########################### STEP 4  ##################################
#       FOD estimation (Multi-tissue spherical deconvolution)        #
######################################################################
# can adjust threads to include more if available, processing is not ran in parallel, hence more threads can be used.
#Single processing
dwi2fod -force -nthreads ${THREADS} msmt_csd $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_dwi_den_preproc_unbiased_upsampled.mif $ROOTFOLDER/derivatives/MRtrix3_group/group_average_response_wm.txt $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_wmfod.mif $ROOTFOLDER/derivatives/MRtrix3_group/group_average_response_gm.txt $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_gmfod.mif $ROOTFOLDER/derivatives/MRtrix3_group/group_average_response_csf.txt $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_csffod.mif -mask $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_dwi_mask_upsampled.mif
#Loop processing
for_each $ROOTFOLDER/derivatives/MRtrix3/* : dwi2fod -force -nthreads ${THREADS} msmt_csd IN/dwi/NAME_dwi_den_preproc_unbiased_upsampled.mif $ROOTFOLDER/derivatives/MRtrix3_group/group_average_response_wm.txt IN/dwi/NAME_wmfod.mif $ROOTFOLDER/derivatives/MRtrix3_group/group_average_response_gm.txt IN/dwi/NAME_gmfod.mif $ROOTFOLDER/derivatives/MRtrix3_group/group_average_response_csf.txt IN/dwi/NAME_csffod.mif -mask IN/dwi/NAME_dwi_mask_upsampled.mif

########################### STEP 5  ##################################
#  Joint bias field correction and intensity normalisation           #
######################################################################
#Single processing
mtnormalise -force -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_wmfod.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_wmfod_norm.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_gmfod.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_gmfod_norm.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_csffod.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_csffod_norm.mif -mask $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_dwi_mask_upsampled.mif
#Loop processing
for_each $ROOTFOLDER/derivatives/MRtrix3/* : mtnormalise -force -nthreads ${THREADS} IN/dwi/NAME_wmfod.mif IN/dwi/NAME_wmfod_norm.mif IN/dwi/NAME_gmfod.mif IN/dwi/NAME_gmfod_norm.mif IN/dwi/NAME_csffod.mif IN/dwi/NAME_csffod_norm.mif -mask IN/dwi/NAME_dwi_mask_upsampled.mif

########################### STEP 6  ##################################
#                Generate a study-specific FOD tempate               #
######################################################################
mkdir -p $ROOTFOLDER/derivatives/MRtrix3_group/template/fod_input
mkdir $ROOTFOLDER/derivatives/MRtrix3_group/template/mask_input

#For whole population
for_each $ROOTFOLDER/derivatives/MRtrix3/* : ln -sr IN/dwi/NAME_wmfod_norm.mif $ROOTFOLDER/derivatives/MRtrix3_group/template/fod_input/PRE.mif
for_each $ROOTFOLDER/derivatives/MRtrix3/* : ln -sr IN/dwi/NAME_dwi_mask_upsampled.mif $ROOTFOLDER/derivatives/MRtrix3_group/template/mask_input/PRE.mif

#For selected population - file needs to have group labelled (e.g. _patient, _control)
for_each `ls -d *patient | sort -R | tail -20` : ln -sr IN/dwi/NAME_wmfod_norm.mif $ROOTFOLDER/derivatives/MRtrix3_group/template/fod_input/PRE.mif
for_each `ls -d *control | sort -R | tail -20` : ln -sr IN/dwi/NAME_dwi_mask_upsampled.mif $ROOTFOLDER/derivatives/MRtrix3_group/mask_input/PRE.mif

#Step for generating the template
population_template -force -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix3_group/template/fod_input -mask_dir $ROOTFOLDER/derivatives/MRtrix3_group/template/mask_input $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template.mif -voxel_size 1.25

########################### STEP 7  ##################################
#           Register subjs FOD images to FOD templates               #
######################################################################
# Single processing
mrregister -force -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_wmfod_norm.mif -mask1 $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_dwi_mask_upsampled.mif $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template.mif -nl_warp $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_subj2template_warp.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_template2subj_warp.mif
# Loop Processing
for_each $ROOTFOLDER/derivatives/MRtrix3/* : mrregister -force -nthreads ${THREADS} IN/dwi/NAME_wmfod_norm.mif -mask1 IN/dwi/NAME_dwi_mask_upsampled.mif $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template.mif -nl_warp IN/dwi/NAME_subj2template_warp.mif IN/dwi/NAME_template2subj_warp.mif


########################### STEP 8  ##################################
#  Compute the template mask of all subjs masks in template space    #
######################################################################
# Single processing
mrtransform -force -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_dwi_mask_upsampled.mif -warp $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_subj2template_warp.mif -interp nearest -datatype bit $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_mask_in_template_space.mif

# Loop Processing
for_each $ROOTFOLDER/derivatives/MRtrix3/* : mrtransform -force -nthreads ${THREADS} IN/dwi/NAME_dwi_mask_upsampled.mif -warp IN/dwi/NAME_subj2template_warp.mif -interp nearest -datatype bit IN/dwi/NAME_mask_in_template_space.mif


mrmath -force -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix3/*/dwi/*_mask_in_template_space.mif min $ROOTFOLDER/derivatives/MRtrix3_group/template/group_template_mask.mif

########################### STEP 9  ##################################
#             Compute a WM template analysis fixel mask              #
######################################################################
## To conduct a check using `mrview` to examine index.mif to check if 0.06 is a suitable value. If there are missing anatomy, regenerate with lower value.
## Use `mrinfo -size */fixel_mask/directions.mif` to check for the size of images along the first dimension

fod2fixel -mask $ROOTFOLDER/derivatives/MRtrix3_group/template/group_template_mask.mif -fmls_peak_value 0.06 $ROOTFOLDER/derivatives/MRtrix3_group/template/wmfod_template.mif $ROOTFOLDER/derivatives/MRtrix3_group/template/fixel_mask

########################### STEP 10 ##################################
#                 Warp FOD images to template space                  #
######################################################################
# Single processing
mrtransform -force -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_wmfod_norm.mif -warp $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_subj2template_warp.mif -reorient_fod no $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_fod_in_template_space_NOT_REORIENTED.mif

# Loop Processing
for_each $ROOTFOLDER/derivatives/MRtrix3/* : mkdir -p IN/dwi/fixel
for_each $ROOTFOLDER/derivatives/MRtrix3/* : mrtransform -force -nthreads ${THREADS} IN/dwi/NAME_wmfod_norm.mif -warp IN/dwi/NAME_subj2template_warp.mif -reorient_fod no IN/dwi/fixel/NAME_fod_in_template_space_NOT_REORIENTED.mif

################################ STEP 11 ######################################
# Segment FOD images to estimate fixels and their apparent fibre density (FD) #
###############################################################################
# Single processing
fod2fixel -force -nthreads ${THREADS} -mask $ROOTFOLDER/derivatives/MRtrix3_group/template/group_template_mask.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/fixel/${SUB}_fod_in_template_space_NOT_REORIENTED.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/fixel/fixel_in_template_space_NOT_REORIENTED -afd ${SUB}_fd.mif


#Loop Processing (error can occur iif "fixel_in_template_space_NOT_REORIENTED" is not empty, -force cannot overwrite )
for_each $ROOTFOLDER/derivatives/MRtrix3/* : fod2fixel -force -nthreads ${THREADS} -mask $ROOTFOLDER/derivatives/MRtrix3_group/template/group_template_mask.mif -afd NAME_fd.mif IN/dwi/fixel/NAME_fod_in_template_space_NOT_REORIENTED.mif IN/dwi/fixel/fixel_in_template_space_NOT_REORIENTED

########################### STEP 12  #################################
#                            Reorient fixels                         #
######################################################################
#Single processing
fixelreorient -force -nthreads ${THREADS} $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/fixel/fixel_in_template_space_NOT_REORIENTED $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_subj2template_warp.mif $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/fixel/fixel_in_template_space

#Loop Processing
for_each $ROOTFOLDER/derivatives/MRtrix3/* : fixelreorient IN/dwi/fixel/fixel_in_template_space_NOT_REORIENTED IN/dwi/NAME_subj2template_warp.mif IN/dwi/fixel/fixel_in_template_space

# fixel_in_template_space_NOT_REORIENTED can be removed after the above steps is processed.
for_each $ROOTFOLDER/derivatives/MRtrix3/* : rm -r IN/dwi/fixel/fixel_in_template_space_NOT_REORIENTED

########################## STEP 13  ##################################
#              Assign subject fixels to template fixels              # check if this steps creates file with ID
######################################################################

for_each $ROOTFOLDER/derivatives/MRtrix3/* : fixelcorrespondence IN/dwi/fixel/fixel_in_template_space/NAME_fd.mif $ROOTFOLDER/derivatives/MRtrix3_group/template/fixel_mask $ROOTFOLDER/derivatives/MRtrix3_group/template/fd PRE_fd.mif

########################### STEP 14  #################################
#       Compute the fibre cross-section (FC) metric                  #
######################################################################

for_each $ROOTFOLDER/derivatives/MRtrix3/* : warp2metric IN/dwi/NAME_subj2template_warp.mif -fc $ROOTFOLDER/derivatives/MRtrix3_group/template/fixel_mask $ROOTFOLDER/derivatives/MRtrix3_group/template/fc NAME_fc.mif

########################### STEP 15  ##################################
# Compute a combined measure of fibre density and cross-section (FDC) #
#######################################################################
mkdir $ROOTFOLDER/derivatives/MRtrix3_group/template/fdc
cp $ROOTFOLDER/derivatives/MRtrix3_group/template/fc/index.mif $ROOTFOLDER/derivatives/MRtrix3_group/template/fdc
cp $ROOTFOLDER/derivatives/MRtrix3_group/template/fc/directions.mif $ROOTFOLDER/derivatives/MRtrix3_group/template/fdc

for_each $ROOTFOLDER/derivatives/MRtrix3/* : mrcalc $ROOTFOLDER/derivatives/MRtrix3_group/template/fd/NAME_fd.mif  $ROOTFOLDER/derivatives/MRtrix3_group/template/fc/NAME_fc.mif -mult $ROOTFOLDER/derivatives/MRtrix3_group/template/fdc/NAME_fdc.mif
########################### STEP 16  ################################
#  Perform whole-brain fibre tractography on the FOD template       #
#####################################################################

cd $ROOTFOLDER/derivatives/MRtrix3_group/template
tckgen -angle 22.5 -maxlen 250 -minlen 10 -power 1.0 wmfod_template.mif -seed_image group_template_mask.mif -mask group_template_mask.mif -select 20000000 -cutoff 0.06 tracks_20_million.tck

########################## STEP 17  ##################################
#        Reduce biases in tractogram densities                       #
######################################################################

tcksift tracks_20_million.tck wmfod_template.mif tracks_2_million_sift.tck -term_number 2000000

########################### STEP 18  #################################
#               Generate fixel-fixel connectivity matrix             #
######################################################################

fixelconnectivity fixel_mask/ tracks_2_million_sift.tck matrix/

########################### STEP 19  #################################
#        Smooth fixel data using fixel-fixel connectivity            #
######################################################################
#TODO: NEXT STEP
fixelfilter fd smooth fd_smooth -matrix matrix/
fixelfilter log_fc smooth log_fc_smooth -matrix matrix/
fixelfilter fdc smooth fdc_smooth -matrix matrix/


########################### STEP 20  #################################
#           Perform statistical analysis of FD, FC, and FDC          #
######################################################################
fixelcfestats fd_smooth/ fd_files.txt design_matrix.txt contrast.txt matrix/ stats_fd/
fixelcfestats fdc_smooth/ fdc_files.txt design_matrix.txt contrast.txt matrix/ stats_fdc/
fixelcfestats log_fc_smooth/ files.txt design_matrix.txt contrast_matrix.txt matrix/ stats_log_fc/

########################### STEP 21  #################################
#                       Visualise the results                        #
######################################################################
#To view the results load the population FOD template image in mrview, and overlay the fixel images using the vector plot tool. Note that p-value images are saved as (1 - p-value). Therefore to visualise all results at a threshold of p < 0.05, within the mrview fixel plot tool, apply a lower threshold at a value of 0.95.

#visualise in 2d
mrview wmfod_template.mif -overlay.load ./stats_fd/fwe_1mpvalue.mif
mrview wmfod_template.mif -overlay.load ./stats_fdc/fwe_1mpvalue.mif

#visualise in 3d
tckedit tracks_2_million_sift.tck -num 200000 tracks_200k_sift.tck
fixel2tsf stats_fdc/fwe_1mpvalue.mif tracks_200k_sift.tck fdc_fwe_pvalue.tsf
fixel2tsf stats_fdc/abs_effect_size.mif tracks_200k_sift.tck fdc_abs_effect_size.tsf

#Generate text files
ls -1 fd_smooth/sub* | xargs -n 1 basename > fd_files.txt
ls -1 fdc_smooth/sub* | xargs -n 1 basename > fdc_files.txt