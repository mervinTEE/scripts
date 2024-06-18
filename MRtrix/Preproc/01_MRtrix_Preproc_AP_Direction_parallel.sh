# Find all subject folders containing "sub-" and get their basenames
ROOTFOLDER=/home/admin/Desktop/MRI/MT/5DTI

# Loop over each subject folder, extract the basename, and call the shell script
for dir in $ROOTFOLDER/rawdata/*; do
    SUB_ID=$(basename "$dir")
    echo "Processing $SUB_ID"
    source /home/admin/Desktop/MRIapp/scripts/DTI/MRtrix_Analysis_Scripts-master/01_MRtrix_Preproc_AP_Direction_personal.sh $ROOTFOLDER $SUB_ID 20
done
######################## Code Above is working fine, for SINGLE subj at a time ########################
######################################################################################################
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
    taskset -c 0-19 bash -c "source /home/admin/Desktop/MRIapp/scripts/DTI/MRtrix/Preproc/01_MRtrix_Preproc_AP_Direction_single.sh $ROOTFOLDER $SUB_ID 4"
}

export ROOTFOLDER  # Export ROOTFOLDER so it's available in the parallel process

# Use find to list the directories and parallel to process them
find "$ROOTFOLDER/rawdata" -maxdepth 1 -type d -name "sub-*" | parallel -j 5 bash -c "$(declare -f process_dir); process_dir {}" _

