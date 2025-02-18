########################################## TO RANDOMISE SUBID AND FILES #################################################
#########################################################################################################################
library(fs)      # For file system operations
library(dplyr)   # For data manipulation
library(tidyr)   # For data tidying

# Directory paths
SOURCE_DIR <- "/mnt/hdd/MT/NEURO_BMC/NEURO-WMH/derivatives/LST_MNI"
DEST_DIR <- "/mnt/hdd/MT/NEURO_BMC/NEURO-WMH/derivatives/test"

# Create destination directory if it doesn't exist
dir_create(DEST_DIR)

# Number of raters
NUM_RATERS <- 4

# Create rater directories
for(i in 1:NUM_RATERS) {
  dir_create(file.path(DEST_DIR, paste0("Rater", i)))
}

# Initialize CSV file for mapping
csv_file <- file.path(DEST_DIR, "rater_file_mapping.csv")
mapping_df <- data.frame(
  Anonymized_Filename = character(),
  Rater = character(),
  Original_Filename = character()
)

# Get all subject directories
subjects <- dir_ls(SOURCE_DIR, type = "directory")

# Randomly select 50 subject folders
selected_subjects <- sample(subjects, 50)

# Generate random numbers from 1 to 999
numbers <- sample(1:999, length(selected_subjects) * NUM_RATERS)
number_counter <- 1

# Process each selected subject
for(subject in selected_subjects) {
  subject_id <- basename(subject)
  
  # Process for each rater
  for(rater in 1:NUM_RATERS) {
    # Get unique number for this subject and rater
    random_number <- numbers[number_counter]
    number_counter <- number_counter + 1
    
    anonymized_subject <- sprintf("Subject%03d_Rater%d", random_number, rater)
    
    # Create destination directory
    dest_subject_dir <- file.path(DEST_DIR, paste0("Rater", rater), anonymized_subject)
    dir_create(dest_subject_dir)
    
    # Find all .nii.gz files in the subject directory
    nii_files <- dir_ls(subject, glob = "*.nii.gz")
    
    if(length(nii_files) > 0) {
      for(file in nii_files) {
        original_filename <- basename(file)
        
        # Create new filename
        new_filename <- paste0(anonymized_subject, "_", 
                               sub("^[^_]*_", "", original_filename))
        
        # Define destination path
        dest_file <- file.path(dest_subject_dir, new_filename)
        
        # Copy file
        file_copy(file, dest_file, overwrite = TRUE)
        
        # Add to mapping dataframe
        mapping_df <- rbind(mapping_df, data.frame(
          Anonymized_Filename = new_filename,
          Rater = paste0("Rater", rater),
          Original_Filename = original_filename
        ))
      }
    } else {
      message(sprintf("No .nii.gz files found in %s", subject))
    }
  }
}

# Write mapping to CSV
write.csv(mapping_df, csv_file, row.names = FALSE)

message(sprintf("Anonymized files have been created for all raters and mapped in %s", csv_file))

########################################## TO REVERT FILES BACK TO ORIGINAL ID ##########################################
#########################################################################################################################
library(data.table)
library(stringr)
library(fs)

# Base directory where the subject folders are located
base_dir <- "/mnt/hdd/MT/NEURO_BMC/NEURO-WMH/derivatives/NEURO-BMC_WMH_Original"

# Remove trailing slash from base_dir if it exists
base_dir <- sub("/$", "", base_dir)

# Path to the CSV file
csv_file <- "/mnt/hdd/MT/NEURO_BMC/NEURO-WMH/derivatives/rater_file_mapping.csv"

# Create edited folder at the same level as rater folders
edited_dir <- file.path(base_dir, "edited")

# Function to safely create directory
safe_mkdir <- function(path) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }
}

# Create edited directory
safe_mkdir(edited_dir)

# Function to safely move/rename files
safe_rename <- function(from, to) {
  if (file.exists(from)) {
    safe_mkdir(dirname(to))
    file.rename(from, to)
    return(TRUE)
  }
  return(FALSE)
}

# Function to format edited filename
format_edited_filename <- function(original_subject, rater) {
  # Keep the original subject format (e.g., "sub-NEURO006")
  # Create the new filename
  sprintf("%s_ses-01_PVS_All_ROIs_edited_%s.nii.gz", original_subject, rater)
}

# Read the CSV file
csv_data <- read.csv(csv_file, stringsAsFactors = FALSE)

# Initialize directory mappings list
dir_mappings <- list()

# Process each row in the CSV
for (i in 1:nrow(csv_data)) {
  anonymized_filename <- csv_data$Anonymized_Filename[i]
  rater <- csv_data$Rater[i]
  original_filename <- csv_data$Original_Filename[i]
  
  # Skip header if present
  if (anonymized_filename == "Anonymized_Filename") next
  
  # Print current row for debugging
  cat(sprintf("Row: %s, %s, %s\n", 
              anonymized_filename, rater, original_filename))
  
  # Extract subject information
  subject_rater <- paste(unlist(strsplit(anonymized_filename, "_"))[1:2], 
                         collapse = "_")
  original_subject <- unlist(strsplit(original_filename, "_"))[1]
  
  # Get the old directory path
  old_dir <- file.path(base_dir, rater, subject_rater)
  
  # If the directory exists, process all files in it
  if (dir.exists(old_dir)) {
    # Get all files in the directory
    files <- list.files(old_dir, pattern = "\\.nii\\.gz$", full.names = TRUE)
    
    for (file in files) {
      # Get the filename
      filename <- basename(file)
      
      # Check if this is an edited file
      if (grepl("edited", filename)) {
        # Create new filename in the edited format
        new_filename <- format_edited_filename(original_subject, rater)
        new_file_path <- file.path(edited_dir, new_filename)
      } else {
        # Create new filename by replacing the subject ID
        new_filename <- sub(subject_rater, original_subject, filename)
        new_file_path <- file.path(base_dir, rater, original_subject, new_filename)
      }
      
      # Create target directory if it doesn't exist
      safe_mkdir(dirname(new_file_path))
      
      # Rename and move file
      if (safe_rename(file, new_file_path)) {
        cat(sprintf("Renamed and moved file: %s to %s\n", file, new_file_path))
      } else {
        cat(sprintf("Failed to rename file: %s\n", file))
      }
    }
    
    # Store directory mapping for later cleanup
    dir_mappings[[old_dir]] <- file.path(base_dir, rater, original_subject)
  }
}

# Print directory mappings
cat("\nDirectory mappings:\n")
for (old_dir in names(dir_mappings)) {
  cat(sprintf("%s -> %s\n", old_dir, dir_mappings[[old_dir]]))
}

# Remove empty source directories after all files have been moved
for (old_dir in names(dir_mappings)) {
  if (dir.exists(old_dir)) {
    # Check if directory is empty
    if (length(list.files(old_dir)) == 0) {
      unlink(old_dir, recursive = TRUE)
      cat(sprintf("Removed empty directory: %s\n", old_dir))
    } else {
      cat(sprintf("Warning: Directory not empty, cannot remove: %s\n", old_dir))
    }
  }
}

#########################################################################################################################

# Cleaning File formats and names
# Define the base directory
base_dir <- "/mnt/hdd/MT/NEURO_BMC/NEURO-WMH/derivatives/NEURO-BMC_WMH_Raterset/edited"

# Find all files with "_edited" in their name within the base directory
edited_files <- list.files(base_dir, pattern = "_edited\\.nii\\.gz$", recursive = TRUE, full.names = TRUE)

# Loop through each file
for (file_path in edited_files) {
        # Extract the directory and file name
        dir_path <- dirname(dirname(file_path))
        file_name <- basename(file_path)
        
        # Extract the rater name (assumes it is the immediate folder name, e.g., "Rater1")
        rater_name <- basename(dir_path)
        
        # Construct the new file name
        new_file_name <- sub("(.*_edited)(\\.nii\\.gz$)", paste0("\\1_", rater_name, "\\2"), file_name)
        
        # Construct the full path to the new file
        new_file_path <- file.path(dirname(dir_path), new_file_name)
        
        # Rename the file
        file.rename(file_path, new_file_path)
}

############################################################## ICC #########################################################
## Library Loading for ICC
# Load necessary libraries
library(irr)        # For ICC calculation
library(dplyr)      # For data manipulation
library(oro.nifti)  # For reading .nii.gz files

# Define the directory containing the files
data_dir <- "/mnt/hdd/MT/NEURO_BMC/NEURO-WMH/derivatives/NEURO-BMC_WMH_Original/edited"


################################################################## For TWO RATERS #################################################################
# For TWO Raters
raters <- list(
  Rater1 = list.files(data_dir, pattern = "Rater1.nii.gz", full.names = TRUE),
  Rater2 = list.files(data_dir, pattern = "Rater2.nii.gz", full.names = TRUE)
)

# Find max number of files
max_files <- max(sapply(raters, length))

# Identify raters with mismatched file counts
mismatched <- names(raters)[sapply(raters, length) != max_files]

# Output result
if (length(mismatched) > 0) {
  cat("Raters with mismatched file counts:", paste(mismatched, collapse = ", "), "\n")
} else {
  cat("All raters have the same number of files.\n")
}


# Function to binarised >0 = 1 and extract ROI values from .nii.gz files

extract_roi_values <- function(file) {
  # Read the .nii.gz file
  nii <- readNIfTI(file, reorient = FALSE)
  
  # Binarize the data: all values > 0 become 1, 0 remains 0
  nii[nii > 0] <- 1
  
  # Extract the mean intensity value (now binary, so this is the proportion of non-zero voxels)
  mean_intensity <- mean(nii)  # Mean of binary data is the proportion of 1s
  
  return(mean_intensity)
}

# Remove roi_data if it exists
if (exists("roi_data")) rm(roi_data)

# Create a data frame to store the extracted data
roi_data <- data.frame(
  Subject = character(),
  Rater1 = numeric(),
  Rater2 = numeric(),
  stringsAsFactors = FALSE
)

# Loop through the files and extract ROI values
for (i in seq_along(rater1_files)) {
  # Extract subject ID from the file name
  subject_id <- gsub(".*(sub-NEURO[0-9]+).*", "\\1", raters$Rater1[i])
  
  # Extract ROI values for both raters
  rater1_values <- extract_roi_values(raters$Rater1[i])
  rater2_values <- extract_roi_values(raters$Rater2[i])
  
  # Combine the data into the data frame
  roi_data <- rbind(roi_data, data.frame(
    Subject = subject_id,
    Rater1 = rater1_values,
    Rater2 = rater2_values
  ))
}

# Check the structure of the data
print(head(roi_data))

# Calculate ICC using the irr package
# ICC can be calculated for different models (e.g., single measures, average measures)
icc_result_original <- icc(roi_data[, c("Rater1", "Rater2")], model = "twoway", type = "agreement", unit = "single")

# Print the ICC result
print(icc_result_rater)
print(icc_result_original)

# Identify Outlier ICC values
#Calculate variance, standard deviation, and max difference for each subject
roi_out <- roi_data %>%
  rowwise() %>%
  mutate(
    Variance = var(c(Rater1, Rater2)),
    SD = sd(c(Rater1, Rater2)),
    MaxDiff = max(c(Rater1, Rater2)) - min(c(Rater1, Rater2))
  )

# Identify subjects with high disagreement using variance (top 25%)
variance_threshold <- quantile(roi_out$Variance, 0.75)
high_variance_subjects <- roi_out %>%
  filter(Variance > variance_threshold) %>%
  arrange(desc(Variance))

# For more extreme outliers (1.5*IQR rule)
iqr_threshold <- quantile(roi_out$Variance, 0.75) + 1.5 * IQR(roi_out$Variance)
high_variance_outliers <- roi_out %>%
  filter(Variance > iqr_threshold) %>%
  arrange(desc(Variance))

# View results
cat("Subjects with highest variance (top 25%):\n")
print(high_variance_subjects)

cat("\nSubjects with extreme variance (potential outliers):\n")
print(high_variance_outliers)




################################################## For FOUR RATERS ########################################################
# For FOUR Raters
raters <- list(
  Rater1 = list.files(data_dir, pattern = "Rater1.nii.gz", full.names = TRUE),
  Rater2 = list.files(data_dir, pattern = "Rater2.nii.gz", full.names = TRUE),
  Rater3 = list.files(data_dir, pattern = "Rater3.nii.gz", full.names = TRUE),
  Rater4 = list.files(data_dir, pattern = "Rater4.nii.gz", full.names = TRUE)
)

# Find max number of files
max_files <- max(sapply(raters, length))

# Identify raters with mismatched file counts
mismatched <- names(raters)[sapply(raters, length) != max_files]

# Output result
if (length(mismatched) > 0) {
  cat("Raters with mismatched file counts:", paste(mismatched, collapse = ", "), "\n")
} else {
  cat("All raters have the same number of files.\n")
}


# Function to binarised >0 = 1 and extract ROI values from .nii.gz files

extract_roi_values <- function(file) {
  # Read the .nii.gz file
  nii <- readNIfTI(file, reorient = FALSE)
  
  # Binarize the data: all values > 0 become 1, 0 remains 0
  nii[nii > 0] <- 1
  
  # Extract the mean intensity value (now binary, so this is the proportion of non-zero voxels)
  mean_intensity <- mean(nii)  # Mean of binary data is the proportion of 1s
  
  return(mean_intensity)
}

# Remove roi_data if it exists
if (exists("roi_data")) rm(roi_data)


# Create a data frame to store the extracted data
roi_data <- data.frame(
        Subject = character(),
        Rater1 = numeric(),
        Rater2 = numeric(),
        Rater3 = numeric(),
        Rater4 = numeric(),
        stringsAsFactors = FALSE
)

# Loop through the files and extract ROI values
for (i in seq_along(rater1_files)) {
        # Extract subject ID from the file name
        subject_id <- gsub(".*(HD[0-9]+).*", "\\1", raters$Rater1[i])
        
        # Extract ROI values for both raters
        rater1_values <- extract_roi_values(raters$Rater1[i])
        rater2_values <- extract_roi_values(raters$Rater2[i])
        rater3_values <- extract_roi_values(raters$Rater3[i])
        rater4_values <- extract_roi_values(raters$Rater4[i])
        
        # Combine the data into the data frame
        roi_data <- rbind(roi_data, data.frame(
                Subject = subject_id,
                Rater1 = rater1_values,
                Rater2 = rater2_values,
                Rater3 = rater3_values,
                Rater4 = rater4_values
        ))
}

# Check the structure of the data
print(head(roi_data))

# Calculate ICC using the irr package
# ICC can be calculated for different models (e.g., single measures, average measures)
icc_result <- icc(roi_data[, c("Rater1", "Rater2","Rater3", "Rater4")], model = "twoway", type = "agreement", unit = "single")

# Print the ICC result
print(icc_result)

# Identify Outlier ICC values
#Calculate variance, standard deviation, and max difference for each subject
roi_out <- roi_data %>%
  rowwise() %>%
  mutate(
    Variance = var(c(Rater1, Rater2, Rater3, Rater4)),
    SD = sd(c(Rater1, Rater2, Rater3, Rater4)),
    MaxDiff = max(c(Rater1, Rater2, Rater3, Rater4)) - min(c(Rater1, Rater2, Rater3, Rater4))
  )

# Identify subjects with high disagreement using variance (top 25%)
variance_threshold <- quantile(roi_out$Variance, 0.75)
high_variance_subjects <- roi_out %>%
  filter(Variance > variance_threshold) %>%
  arrange(desc(Variance))

# For more extreme outliers (1.5*IQR rule)
iqr_threshold <- quantile(roi_out$Variance, 0.75) + 1.5 * IQR(roi_out$Variance)
high_variance_outliers <- roi_out %>%
  filter(Variance > iqr_threshold) %>%
  arrange(desc(Variance))

# View results
cat("Subjects with highest variance (top 25%):\n")
print(high_variance_subjects)

cat("\nSubjects with extreme variance (potential outliers):\n")
print(high_variance_outliers)

###################################################################################################################################

# DICE Coefficient
## Loading Libraries
library(pacman)
p_load(dplyr, skimr, ggplot2, tidyverse, cowplot, readxl, janitor, psych, oro.nifti)

## Loading nifti files
# List all files in the directory
all_files <- list.files(base_dir, full.names = TRUE) # change to root path of your nifti files

# Filter files based on _JB and _V
R1_files <- grep("_Rater1.nii.gz", all_files, value = TRUE)
R2_files <- grep("_Rater2.nii.gz", all_files, value = TRUE)

# Sort the lists for pairing
R1_files <- sort(R1_files)
R2_files <- sort(R2_files)

# Check the sorted files
print(R1_files)
print(R2_files)




#Generating DICE Coefficient

# Assuming R1_files and R2_files are vectors containing file paths for R1 and R2 masks

# Function to calculate Dice Similarity Coefficient
calculate_dice_similarity <- function(rater1_mask, rater2_mask) {
        # Your implementation of Dice Similarity Coefficient calculation
        # Replace the following line with your actual calculation
        dice_coefficient <- sum(rater1_mask * rater2_mask) * 2 / (sum(rater1_mask) + sum(rater2_mask))
        return(dice_coefficient)
}


# Iterate through the pairs and calculate Dice Similarity Coefficient
dice_coefficients <- sapply(1:length(R1_files), function(i) {
        rater1_mask <- readNIfTI(R1_files[i], reorient = FALSE)
        rater2_mask <- readNIfTI(R2_files[i], reorient = FALSE)
        calculate_dice_similarity(rater1_mask, rater2_mask)
})

# Create a data frame to store the results
dice_df <- data.frame(filename = basename(R1_files),
                      SubjectPair = 1:length(R1_files),
                      DiceCoefficient = dice_coefficients
)

# Print Dice Coefficients and Mean DICE coefficient
dice_df %>% arrange(DiceCoefficient)
print(paste("Mean DICE coefficient: ", mean(dice_coefficients)))


# Assuming R1_files and R2_files are vectors containing file paths for JB and V masks

# Function to extract a unique ID from file paths
extract_id_from_path <- function(file_path) {
        # Modify this function to extract the unique ID from your file paths
        # Replace the following line with your actual implementation
        id <- tools::file_path_sans_ext(basename(file_path))
        return(id)
}

# Iterate through the pairs and calculate Dice Similarity Coefficient
dice_coefficients <- sapply(1:length(R1_files), function(i) {
        rater1_mask <- readNIfTI(R1_files[i], reorient = FALSE)
        rater2_mask <- readNIfTI(R2_files[i], reorient = FALSE)
        calculate_dice_similarity(rater1_mask, rater2_mask)
})

# Extract unique IDs from file paths
subject_ids <- sapply(R1_files, extract_id_from_path)

# Create a data frame to store the results
dice_df <- data.frame(
        SubjectPair = subject_ids,
        DiceCoefficient = dice_coefficients
)

# Print Dice Coefficients and Mean DICE coefficient
print(dice_df)
print(paste("Mean DICE coefficient: ", mean(dice_coefficients)))

# Plot Dice Coefficients
plot(dice_df$SubjectPair, dice_df$DiceCoefficient,
     xlab = "Subject Pair ID", ylab = "Dice Coefficient",
     main = "Dice Coefficients between R1 and R2")

# Export CSV
write.csv(dice_df, file = "dice_coefficients.csv", row.names = FALSE)


###################################################################################################################################
# DICE for four Raters
###################################################################################################################################

# Load necessary libraries
library(oro.nifti)
library(dplyr)

# List all files in the directory
all_files <- list.files(base_dir, full.names = TRUE)

# Filter files based on the rater labels
R1_files <- grep("_Rater1.nii.gz", all_files, value = TRUE)
R2_files <- grep("_Rater2.nii.gz", all_files, value = TRUE)
R3_files <- grep("_Rater3.nii.gz", all_files, value = TRUE)
R4_files <- grep("_Rater4.nii.gz", all_files, value = TRUE)

# Sort the lists for consistent pairing
R1_files <- sort(R1_files)
R2_files <- sort(R2_files)
R3_files <- sort(R3_files)
R4_files <- sort(R4_files)

# Debugging: Print sorted file lists
print(R1_files)
print(R2_files)
print(R3_files)
print(R4_files)

# Function to binarize NIfTI masks
binarize_mask <- function(mask) {
        mask[mask > 0] <- 1
        return(mask)
}

# Function to calculate Dice Similarity Coefficient
calculate_dice_similarity <- function(mask1, mask2) {
        # Check for empty masks
        if (sum(mask1) == 0 & sum(mask2) == 0) {
                return(1)  # Both masks are empty
        } else if (sum(mask1) == 0 | sum(mask2) == 0) {
                return(0)  # One mask is empty
        }
        # Calculate Dice Coefficient
        dice_coefficient <- sum(mask1 * mask2) * 2 / (sum(mask1) + sum(mask2))
        return(dice_coefficient)
}

# Function to extract mean intensity value for binary masks
extract_roi_values <- function(file) {
        nii <- readNIfTI(file, reorient = FALSE)
        nii <- binarize_mask(nii)  # Binarize the mask
        mean_intensity <- mean(nii)  # Proportion of non-zero voxels
        return(mean_intensity)
}

# Iterate through all raters and calculate Dice coefficients
dice_results <- list()

for (i in 1:length(R1_files)) {
        # Read and binarize masks for all raters
        rater1_mask <- binarize_mask(readNIfTI(R1_files[i], reorient = FALSE))
        rater2_mask <- binarize_mask(readNIfTI(R2_files[i], reorient = FALSE))
        rater3_mask <- binarize_mask(readNIfTI(R3_files[i], reorient = FALSE))
        rater4_mask <- binarize_mask(readNIfTI(R4_files[i], reorient = FALSE))
        
        # Calculate Dice coefficients for pairwise comparisons
        dice12 <- calculate_dice_similarity(rater1_mask, rater2_mask)
        dice13 <- calculate_dice_similarity(rater1_mask, rater3_mask)
        dice14 <- calculate_dice_similarity(rater1_mask, rater4_mask)
        dice23 <- calculate_dice_similarity(rater2_mask, rater3_mask)
        dice24 <- calculate_dice_similarity(rater2_mask, rater4_mask)
        dice34 <- calculate_dice_similarity(rater3_mask, rater4_mask)
        
        # Extract mean ROI values for debugging or additional analysis
        mean_r1 <- extract_roi_values(R1_files[i])
        mean_r2 <- extract_roi_values(R2_files[i])
        mean_r3 <- extract_roi_values(R3_files[i])
        mean_r4 <- extract_roi_values(R4_files[i])
        
        # Save results for each subject
        dice_results[[i]] <- data.frame(
                SubjectID = basename(R1_files[i]),
                Dice12 = dice12,
                Dice13 = dice13,
                Dice14 = dice14,
                Dice23 = dice23,
                Dice24 = dice24,
                Dice34 = dice34,
                MeanR1 = mean_r1,
                MeanR2 = mean_r2,
                MeanR3 = mean_r3,
                MeanR4 = mean_r4
        )
}

# Combine all results into a single data frame
dice_df <- do.call(rbind, dice_results)

# Print the results
print(dice_df)

# Calculate overall mean Dice coefficients
mean_dice <- colMeans(dice_df[, grep("Dice", colnames(dice_df))])
print(mean_dice)

# Export results to a CSV
write.csv(dice_df, file = "/mnt/hdd/MT/HARMY/HARMY_PVS/derivatives/Baseline/Rater/dice_coefficients_4_raters.csv", row.names = FALSE)

# Plot Dice coefficients
library(reshape2)
library(ggplot2)
# Melt the dice_df to transform it into a long format
melted_dice_df <- melt(dice_df, id.vars = "SubjectID")

# Plot Dice coefficients as a boxplot
ggplot(melted_dice_df, aes(x = variable, y = value, fill = variable)) +
        geom_boxplot() +
        labs(
                title = "Distribution of Dice Coefficients Across Raters",
                x = "Rater Pairs",
                y = "Dice Coefficient"
        ) +
        theme_minimal() +
        theme(
                legend.position = "none", # Hide the legend
                axis.text.x = element_text(angle = 45, hjust = 1) # Rotate x-axis labels for better readability
        )



