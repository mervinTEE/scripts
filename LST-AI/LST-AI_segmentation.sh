# Setting Root Folder
ROOTFOLDER=/mnt/hdd/MT/EDIS/EDIS_ASL

#THIS COMMAND USES MRTrix3 for_each command, make sure to have MRTrix3 installed

#For Segmentation and annotation from scratch, with 4 parallel loops runnings concurrently using 4 thread for each loop, change -nthreads for more loops, --threads for more cores per loop.
for_each -nthreads 4 -info $ROOTFOLDER/rawdata/* : lst --t1 IN/anat/NAME_T1w.nii.gz --flair IN/anat/NAME_FLAIR.nii.gz --output $ROOTFOLDER/derivatives/LST/NAME --temp $ROOTFOLDER/derivatives/LST/NAME/temp  --device 0 --threads 5

#For Annotation only with existing LST segmentation
for_each -nthreads 4 -info $ROOTFOLDER/rawdata/* : lst --t1 IN/NAME_T1w.nii.gz --flair IN/rmNAME_FLAIR.nii.gz --output $ROOTFOLDER/Output/NAME --temp $ROOTFOLDER/temp/NAME --existing_seg $ROOTFOLDER/corrected/ples_lga_0.3_rmNAME_WMH_corrected.nii.gz --device 0 --annotate_only --threads 4
