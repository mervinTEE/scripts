export ATLASFOLDER=/home/admin/Desktop/MRI/MNI

# Get lateral ventricles from Harvard-Oxford
# Extract lateral ventricles (labels 3 and 14) from Harvard-Oxford atlas
fslmaths $FSLDIR/data/atlases/HarvardOxford/HarvardOxford-sub-maxprob-thr0-1mm.nii.gz \
-thr 3 -uthr 3 -bin $ATLASFOLDER/latvent_L.nii.gz

fslmaths $FSLDIR/data/atlases/HarvardOxford/HarvardOxford-sub-maxprob-thr0-1mm.nii.gz \
-thr 14 -uthr 14 -bin $ATLASFOLDER/latvent_R.nii.gz

# Combine left and right into one binary mask
fslmaths $ATLASFOLDER/latvent_R.nii.gz -add $ATLASFOLDER/latvent_L.nii.gz -bin $ATLASFOLDER/ventricles_bin.nii.gz

# Create Euclidean distance map from the binary mask
fslmaths $ATLASFOLDER/ventricles_bin.nii.gz -edge -bin $ATLASFOLDER/edge_mask.nii.gz
distancemap -i $ATLASFOLDER/ventricles_bin.nii.gz -o $ATLASFOLDER/distmap.nii.gz

# Creating PVWM mask (<=10mm)
fslmaths $ATLASFOLDER/distmap.nii.gz -uthr 10 $ATLASFOLDER/pvwm_mask.nii.gz

# Creating DWM mask (>10mm)
fslmaths $ATLASFOLDER/distmap.nii.gz -thr 10 $ATLASFOLDER/dwm_mask.nii.gz

fast -t 1 -n 3 -H 0.1 -I 4 -l 20.0 -g -o mni_fast $ATLASFOLDER/MNI152_T1_1mm.nii.gz

# Threshold probabilistic WM mask
fslmaths $ATLASFOLDER/mni_fast_pve_2.nii.gz -thr 0.5 -bin $ATLASFOLDER/wm_mask.nii.gz


# Final PVWM and DWM masks restricted to white matter
fslmaths $ATLASFOLDER/pvwm_mask.nii.gz -mul $ATLASFOLDER/wm_mask.nii.gz $ATLASFOLDER/pvwm_in_wm.nii.gz
fslmaths $ATLASFOLDER/dwm_mask.nii.gz -mul $ATLASFOLDER/wm_mask.nii.gz $ATLASFOLDER/dwm_in_wm.nii.gz


# PVWM-WMH

fslmaths /mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/bl/sub-HD006/sub-HD006_WMH_to_MNI.nii.gz -mas /home/admin/Desktop/MRI/MNI/pvwm_in_wm.nii.gz /mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/bl/sub-HD006/WMH_PVWM.nii.gz

# DWM-WMH
fslmaths /mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/bl/sub-HD006/sub-HD006_WMH_to_MNI.nii.gz -mas /home/admin/Desktop/MRI/MNI/dwm_in_wm.nii.gz /mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/bl/sub-HD006/WMH_DWM.nii.gz

# Voxels, Volume(mm3) to divide by 1000 for ml
fslstats /mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/bl/sub-HD006/WMH_PVWM.nii.gz -V
fslstats /mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal/bl/sub-HD006/WMH_DWM.nii.gz -V
