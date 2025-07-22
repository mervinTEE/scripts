
export ROOTFOLDER=/mnt/hdd/MT/HARMY/HARMY_WMH/rawdata_BL
export CORRECTED=/mnt/hdd/MT/HARMY/HARMY_WMH/corrected
export CORRECTED_MNI=/mnt/hdd/MT/HARMY/HARMY_WMH/corrrected_MNI



for_each -nthreads 10 -info $ROOTFOLDER/* : antsRegistrationSyNQuick.sh \
-d 3 \
-f /home/admin/Desktop/MRI/MNI152_T1_1mm.nii.gz \
-m $ROOTFOLDER/NAME/NAME_T1w.nii.gz \
-o $ROOTFOLDER/NAME/T1_to_MNI_


for_each -nthreads 10 -info $ROOTFOLDER/* : antsApplyTransforms \
-d 3 \
-i $ROOTFOLDER/NAME/FLAIR_to_T1_Warped.nii.gz \
-r /home/admin/Desktop/MRI/MNI152_T1_1mm.nii.gz \
-o $ROOTFOLDER/NAME/FLAIR_in_MNI.nii.gz \
-t $ROOTFOLDER/NAME/T1_to_MNI_1Warp.nii.gz \
-t $ROOTFOLDER/NAME/T1_to_MNI_0GenericAffine.mat \
-n NearestNeighbor

#Apply transform of T1-MNI transform to WMH-T1_WMH
for_each -nthreads 10 -info $ROOTFOLDER/* : antsApplyTransforms \
-d 3 \
-i $CORRECTED/ples_lga_0.3_rmNAME_WMH_corrected.nii.gz \
-r /home/admin/Desktop/MRI/MNI152_T1_1mm.nii.gz \
-o $CORRECTED_MNI/NAME/NAME_WMH_in_MNI.nii.gz \
-t $ROOTFOLDER/NAME/T1_to_MNI_1Warp.nii.gz \
-t $ROOTFOLDER/NAME/T1_to_MNI_0GenericAffine.mat \
-n NearestNeighbor
