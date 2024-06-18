#!/bin/bash
################################################################For Single Subject################################################################
##################################################################################################################################################
ROOTFOLDER=/home/admin/Desktop/MRI/MT/1DTI
SUBJ=sub-SPAC001

#Convert the labels of the FreeSurfer parcellation to a format that MRtrix understands. This requires recon-all to have been run on the subject (edit mrtrix path according to how it was installed)
labelconvert -force $ROOTFOLDER/derivatives/fs/${SUBJ}/mri/aparc+aseg.mgz $FREESURFER_HOME/FreeSurferColorLUT.txt /home/admin/anaconda3/share/mrtrix3/labelconvert/fs_default.txt $ROOTFOLDER/derivatives/MRtrix3/${SUBJ}/anat/${SUBJ}_parcels.mif

#Unclear if the line below is needed; it seems to make the coregistration worse. Maybe it is only needed for atlases aside from the default FreeSurfer atlases
#mrtransform $ROOTFOLDER/derivatives/MRtrix3/${SUBJ}/anat/${SUBJ}_parcels.mif -interp nearest -linear $ROOTFOLDER/derivatives/MRtrix3/${SUBJ}/anat/diff2struct_mrtrix.txt -inverse -datatype uint32 $ROOTFOLDER/derivatives/MRtrix3/${SUBJ}/anat/${SUBJ}_parcels_coreg.mif

#Create a whole-brain connectome, representing the streamlines between each parcellation pair in the atlas (in this case, 84x84). The "symmetric" option will make the lower diagonal the same as the upper diagonal, and the "scale_invnodevol" option will scale the connectome by the inverse of the size of the node
#tck2connectome -symmetric -zero_diagonal -scale_invnodevol -tck_weights_in sift_1M.txt sub-01_parcels.mif sub-01_parcels.csv -out_assignment assignments_sub-01_parcels.csv
tck2connectome -force -symmetric -zero_diagonal -scale_invnodevol -tck_weights_in $ROOTFOLDER/derivatives/MRtrix3/${SUBJ}/dwi/${SUBJ}_sift_1M.txt $ROOTFOLDER/derivatives/MRtrix3/${SUBJ}/dwi/${SUBJ}_tracks_10M.tck $ROOTFOLDER/derivatives/MRtrix3/${SUBJ}/anat/${SUBJ}_parcels.mif ${SUBJ}_parcels.csv -out_assignment $ROOTFOLDER/derivatives/MRtrix3/${SUBJ}/anat/assignments_${SUBJ}_parcels.csv

#Creates a tract file between the specified nodes that can then be visualized in mrview. Replace the "8,10" pair after the "nodes" option with the labels in ~/mrtrix3/share/mrtrix3/labelconvert/fs_default.txt that you are interested in
#connectome2tck -nodes 8,10 -exclusive sift_1mio.tck assignments_sub-01_parcels.csv test

######################################################For looping over multiple subjects########################################################
################################################################################################################################################
ROOTFOLDER=/home/admin/Desktop/MRI/MT/5DTI

# Loop over each subject folder, extract the basename, and call the shell script
for dir in $ROOTFOLDER/rawdata/*; do
    SUB_ID=$(basename "$dir")
    echo "Processing $SUB_ID"
    labelconvert -force $ROOTFOLDER/derivatives/fs/${SUB_ID}/mri/aparc+aseg.mgz $FREESURFER_HOME/FreeSurferColorLUT.txt /home/admin/anaconda3/share/mrtrix3/labelconvert/fs_default.txt $ROOTFOLDER/derivatives/MRtrix3/${SUB_ID}/anat/${SUB_ID}_parcels.mif
    tck2connectome -force -symmetric -zero_diagonal -scale_invnodevol -tck_weights_in $ROOTFOLDER/derivatives/MRtrix3/${SUB_ID}/dwi/${SUB_ID}_sift_1M.txt $ROOTFOLDER/derivatives/MRtrix3/${SUB_ID}/dwi/${SUB_ID}_tracks_10M.tck $ROOTFOLDER/derivatives/MRtrix3/${SUB_ID}/anat/${SUB_ID}_parcels.mif ${SUB_ID}_parcels.csv -out_assignment $ROOTFOLDER/derivatives/MRtrix3/${SUB_ID}/anat/assignments_${SUB_ID}_parcels.csv
done

######################################################For parallel processing subjects########################################################
################################################################################################################################################
#!/bin/bash

ROOTFOLDER=/home/admin/Desktop/MRI/MT/5DTI

# Define the function to process each directory
process_dir() {
    dir=$1
    SUB_ID=$(basename "$dir")
    echo "Processing $SUB_ID"
    # Run the script with taskset to limit CPU core usage
    # 'taskset' is used to limit how many cores are allocated
    # 0-19 means cores 0 to 19, change based on your system configuration
    taskset -c 0-19 bash -c "labelconvert -force $ROOTFOLDER/derivatives/fs/${SUB_ID}/mri/aparc+aseg.mgz $FREESURFER_HOME/FreeSurferColorLUT.txt /home/admin/anaconda3/share/mrtrix3/labelconvert/fs_default.txt $ROOTFOLDER/derivatives/MRtrix3/${SUB_ID}/anat/${SUB_ID}_parcels.mif
    tck2connectome -force -symmetric -zero_diagonal -scale_invnodevol -tck_weights_in $ROOTFOLDER/derivatives/MRtrix3/${SUB_ID}/dwi/${SUB_ID}_sift_1M.txt $ROOTFOLDER/derivatives/MRtrix3/${SUB_ID}/dwi/${SUB_ID}_tracks_10M.tck $ROOTFOLDER/derivatives/MRtrix3/${SUB_ID}/anat/${SUB_ID}_parcels.mif ${SUB_ID}_parcels.csv -out_assignment $ROOTFOLDER/derivatives/MRtrix3/${SUB_ID}/anat/assignments_${SUB_ID}_parcels.csv"
}

export ROOTFOLDER  # Export ROOTFOLDER so it's available in the parallel process

# Use find to list the directories and parallel to process them (edit the number based number of workers to have)
find "$ROOTFOLDER/rawdata" -maxdepth 1 -type d -name "sub-*" | parallel -j 2 bash -c "$(declare -f process_dir); process_dir {}" _
