#!/bin/bash
#./dicomsort.sh <path input> <path output>
# Define source and destination base directories
source_dir=$1
destination_dir=$2

# Loop through each lower-level subdirectory in the source directory
find "$source_dir" -mindepth 1 -maxdepth 1 -type d | while read -r folder; do
    # Extract the base name of the lower-level subdirectory
    folder_basename=$(basename "$folder")
    
    # Define the destination path with the folder base name included before %PatientName
    parent_dir=$(dirname "$folder")
    parent_basename=$(basename "$parent_dir")
    dest_path="${parent_basename}_${folder_basename}"
    
    # Run dicomsort using the folder basename as part of the output path
    dicomsort "$folder" "$destination_dir/$folder_basename/%StudyDate/%SeriesNumber_%SeriesDescription/%SeriesNumber_%SeriesDescription-%InstanceNumber.dcm" -k
    
    # Check if dicomsort was successful
    if [ $? -eq 0 ]; then
        echo "Successfully sorted $folder_basename."
    else
        echo "Failed to sort $folder_basename."
    fi
done

#%PatientName/
