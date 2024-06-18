#!/bin/bash

# These commands are for quality-checking your diffusion data

#Setting variables (to change for each subject)
SUBID=sub-SPAC001
ROOTFOLDER=/home/admin/Desktop/MRI/MT/1DTI


### Quality checks for Step 2 ###

# Views the voxels used for FOD estimation
echo "Now viewing the voxels used for FOD estimation (Blue=WM; Green=GM; Red=CSF)"
mrview $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_dwi_den_preproc_unbiased.mif -overlay.load $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_voxels.mif

# Views the response functions for each tissue type. The WM function should flatten out at higher b-values, while the other tissues should remain spherical
echo "Now viewing response function for white matter (press right arrow key to view response function for different shells)"
shview $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_wm.txt
echo "Now viewing response function for grey matter"
shview $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_gm.txt
echo "Now viewing response function for CSF"
shview $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_csf.txt

# Views the FODs overlaid on the tissue types (Blue=WM; Green=GM; Red=CSF)
echo "Now viewing the FODs (Blue=WM; Green=GM; Red=CSF)"
mrview $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_vf.mif -odf.load_sh $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_wmfod.mif


### Quality checks for Step 3 ###

# Check alignment of the 5 tissue types before and after alignment (new alignment in red, old alignment in blue)
echo "Checking alignment between grey matter alignment before (blue) and after (red)"
mrview $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_dwi_den_preproc_unbiased.mif -overlay.load $ROOTFOLDER/derivatives/MRtrix3/${SUB}/anat/${SUB}_5tt_nocoreg.mif -overlay.colourmap 2 -overlay.load $ROOTFOLDER/derivatives/MRtrix3/${SUB}/anat/${SUB}_5tt_coreg.mif -overlay.colourmap 1

# Check the seed region (should match up along the GM/WM boundary)
echo "Checking alignment of the seed region with the GM/WM boundary"
mrview $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_dwi_den_preproc_unbiased.mif -overlay.load $ROOTFOLDER/derivatives/MRtrix3/${SUB}/anat/${SUB}_gmwmSeed_coreg.mif


### Quality checks for Step 4 ###

# View the tracks in mrview
echo "Now viewing the tracks in mrview (red=left-to-right; blue=bottom-to-top; green=forward-to-back)"
mrview $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_dwi_den_preproc_unbiased.mif -tractography.load $ROOTFOLDER/derivatives/MRtrix3/${SUB}/dwi/${SUB}_smallerTracks_200k.tck

# View the sifted tracks in mrview
# Uncomment the following line of code if you used tcksift; otherwise, tcksift2 will output a text file with weightings that are used for later commands (e.g., creating the connectome)
#mrview dwi_den_preproc_unbiased.mif -tractography.load sift_1mio.tck
#######################Single Subject################################
cd /home/admin/Desktop/MRI/MT/1DTI/dwifslpreproc-tmp-GGNO8O
totalSlices=`mrinfo dwi.mif | grep Dimensions | awk '{print $6 * $8}'`
totalOutliers=`awk '{ for(i=1;i<=NF;i++)sum+=$i } END { print sum }' dwi_post_eddy.eddy_outlier_map`
echo "If the following number is greater than 10, you may have to discard this subject because of too much motion or corrupted slices"
echo "scale=5; ($totalOutliers / $totalSlices * 100)/1" | bc | tee percentageOutliers.txt
cd ..
#########################################################################################################################
#!/bin/bash

ROOTFOLDER="/home/admin/Desktop/MRI/MT/5DTI"
OUTPUT_FILE="$ROOTFOLDER/derivatives/MRtrix3/motionQC.csv"

# Initialize the CSV file
echo "SubjectID,PercentageOutliers" > $OUTPUT_FILE

# Loop over each subject folder
for dir in $ROOTFOLDER/rawdata/*; do
    # Extract the subject ID from the directory name
    SUB=$(basename $dir)
    
    # Change to the subject's tmp directory
    cd $ROOTFOLDER/tmp/$SUB || continue
    totalSlices=$(mrinfo dwi.mif | grep Dimensions | awk '{print $6 * $8}')
    totalOutliers=$(awk '{ for(i=1;i<=NF;i++)sum+=$i } END { print sum }' dwi_post_eddy.eddy_outlier_map)
    percentageOutliers=$(echo "scale=5; ($totalOutliers / $totalSlices * 100)/1" | bc)
    
    # Append the results to the CSV file
    echo "$SUB,$percentageOutliers" >> $OUTPUT_FILE
    
    # Return to the previous directory
    cd $ROOTFOLDER
done

echo "Motion QC completed. Results are stored in $OUTPUT_FILE."