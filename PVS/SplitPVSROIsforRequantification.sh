# Set root folder
ROOTFOLDER=/home/admin/Desktop/MRI/test
NEWFOLDER=/home/admin/Desktop/MRI/output
SUFFIX=_ori

for FILE in "$ROOTFOLDER"/HD*/Segmentation/PVS/*.nii.gz; do
    # Check if the file name contains "_PVS_"
    if [[ "$FILE" == *"_PVS_"*.nii.gz ]]; then
        # Extract the base name and directory
        BASENAME=$(basename "$FILE" .nii.gz)
        DIRNAME=$(dirname "$FILE")

        # Extract the HD* ID from the path
        HD_ID=$(basename "$(dirname "$(dirname "$(dirname "$FILE")")")")

        # Construct the new file name with the suffix
        NEWFILE="$DIRNAME/original/${BASENAME}${SUFFIX}.nii.gz"

        # Create the directory if it doesn't exist
        mkdir -p "$DIRNAME/original/"

        # Rename the file
        mv "$FILE" "$NEWFILE"
        echo "Renamed $FILE to $NEWFILE"

        # Example of using HD_ID to move files from NEWFOLDER
        # Assuming you want to move files from NEWFOLDER/HD_ID/...
        SOURCE_DIR="$NEWFOLDER/$HD_ID/Segmentation/PVS/"
        if [[ -d "$SOURCE_DIR" ]]; then
            for ALLROI in "$SOURCE_DIR"*_edited.nii.gz; do
                if [[ -f "$ALLROI" ]]; then
                    cp "$ALLROI" "$DIRNAME"
                    echo "Copied $ALLROI to $DIRNAME"
                fi
            done
        else
            echo "Source directory $SOURCE_DIR does not exist."
        fi

        # Add logic to collect "HDXXX_ses-01_PVS_All_ROIs_edited"
        EDITED_DIR="/home/admin/Desktop/MRI/MT/HARMY_PVS/edited/$HD_ID/"
        EDITED_FILE="${EDITED_DIR}${HD_ID}_ses-01_PVS_All_ROIs_edited.nii.gz"
        if [[ -f "$EDITED_FILE" ]]; then
            cp "$EDITED_FILE" "$DIRNAME"
            echo "Copied $EDITED_FILE to $DIRNAME"
        else
            echo "Edited file $EDITED_FILE does not exist."
        fi
    fi
done

# For LBG
for_each $ROOTFOLDER/* : mrcalc IN/Segmentation/PVS/PRE_ses-01_PVS_All_ROIs_edited.nii.gz IN/Segmentation/PVS_Space/PRE_ses-01_LBG.nii.gz -mul IN/Segmentation/PVS/PRE_ses-01_PVS_LeftBG_NAWM.nii.gz
for_each $ROOTFOLDER/* : mrcalc IN/Segmentation/PVS/PRE_ses-01_PVS_All_ROIs_edited.nii.gz IN/Segmentation/PVS_Space/PRE_ses-01_LBG.nii.gz -mul IN/Segmentation/PVS/PRE_ses-01_PVS_LeftBGwithWMH.nii.gz

# For RBG
for_each $ROOTFOLDER/* : mrcalc IN/Segmentation/PVS/PRE_ses-01_PVS_All_ROIs_edited.nii.gz IN/Segmentation/PVS_Space/PRE_ses-01_RBG.nii.gz -mul IN/Segmentation/PVS/PRE_ses-01_PVS_RightBG_NAWM.nii.gz
for_each $ROOTFOLDER/* : mrcalc IN/Segmentation/PVS/PRE_ses-01_PVS_All_ROIs_edited.nii.gz IN/Segmentation/PVS_Space/PRE_ses-01_RBG.nii.gz -mul IN/Segmentation/PVS/PRE_ses-01_PVS_RightBGwithWMH.nii.gz

# For LCSO
for_each $ROOTFOLDER/* : mrcalc IN/Segmentation/PVS/PRE_ses-01_PVS_All_ROIs_edited.nii.gz IN/Segmentation/PVS_Space/PRE_ses-01_LCSO.nii.gz -mul IN/Segmentation/PVS/PRE_ses-01_PVS_LeftCSO_NAWM.nii.gz
for_each $ROOTFOLDER/* : mrcalc IN/Segmentation/PVS/PRE_ses-01_PVS_All_ROIs_edited.nii.gz IN/Segmentation/PVS_Space/PRE_ses-01_LCSO.nii.gz -mul IN/Segmentation/PVS/PRE_ses-01_PVS_LeftCSOwithWMH.nii.gz

# For RCSO
for_each $ROOTFOLDER/* : mrcalc IN/Segmentation/PVS/PRE_ses-01_PVS_All_ROIs_edited.nii.gz IN/Segmentation/PVS_Space/PRE_ses-01_RCSO.nii.gz -mul IN/Segmentation/PVS/PRE_ses-01_PVS_RightCSO_NAWM.nii.gz
for_each $ROOTFOLDER/* : mrcalc IN/Segmentation/PVS/PRE_ses-01_PVS_All_ROIs_edited.nii.gz IN/Segmentation/PVS_Space/PRE_ses-01_RCSO.nii.gz -mul IN/Segmentation/PVS/PRE_ses-01_PVS_RightCSOwithWMH.nii.gz

# For Midbrain
for_each $ROOTFOLDER/* : mrcalc IN/Segmentation/PVS/PRE_ses-01_PVS_All_ROIs_edited.nii.gz IN/Segmentation/PVS_Space/PRE_ses-01_Midbrain.nii.gz -mul IN/Segmentation/PVS/PRE_ses-01_PVS_Midbrain_NAWM.nii.gz
for_each $ROOTFOLDER/* : mrcalc IN/Segmentation/PVS/PRE_ses-01_PVS_All_ROIs_edited.nii.gz IN/Segmentation/PVS_Space/PRE_ses-01_Midbrain.nii.gz -mul IN/Segmentation/PVS/PRE_ses-01_PVS_MidbrainwithWMH.nii.gz

# For Left Hemisphere
for_each $ROOTFOLDER/* : mrcalc IN/Segmentation/PVS/PRE_ses-01_PVS_LeftBG_NAWM.nii.gz IN/Segmentation/PVS/PRE_ses-01_PVS_LeftCSO_NAWM.nii.gz -add IN/Segmentation/PVS/PRE_ses-01_PVS_LeftHemisphere.nii.gz

# For Right Hemisphere
for_each $ROOTFOLDER/* : mrcalc IN/Segmentation/PVS/PRE_ses-01_PVS_RightBG_NAWM.nii.gz IN/Segmentation/PVS/PRE_ses-01_PVS_RightCSO_NAWM.nii.gz -add IN/Segmentation/PVS/PRE_ses-01_PVS_RightHemisphere.nii.gz

# Rename All_ROIs_edited to ALL_ROIs
for_each $ROOTFOLDER/* : mv IN/Segmentation/PVS/PRE_ses-01_PVS_All_ROIs_edited.nii.gz IN/Segmentation/PVS/PRE_ses-01_PVS_All_ROIs.nii.gz
