# Load necessary libraries
library(dplyr)
library(tidyr)

# Define the base directory
base_dir <- "/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/LSTAI_Y4Y5/"

# Get a list of subject directories
subject_dirs <- list.dirs(base_dir, recursive = FALSE, full.names = TRUE)

# Initialize an empty data frame to store results
compiled_data <- data.frame(
        Subject_ID = character(), 
        Periventricular = numeric(), 
        Juxtacortical = numeric(), 
        Subcortical = numeric(), 
        Infratentorial = numeric(), 
        Num_Lesions = numeric(), 
        Num_Vox = numeric(), 
        Lesion_Volume = numeric(), 
        stringsAsFactors = FALSE
)

# Loop through each subject folder
for (subject_dir in subject_dirs) {
        
        # Extract the subject ID from the folder name
        subject_id <- basename(subject_dir)
        
        # Path to the CSV file
        csv_file <- file.path(subject_dir, "annotated_lesion_stats.csv")
        
        # Check if the CSV file exists
        if (file.exists(csv_file)) {
                
                # Read the CSV file
                df <- read.csv(csv_file, stringsAsFactors = FALSE)
                
                # Ensure necessary columns exist
                if (all(c("Region", "Num_Lesions", "Num_Vox", "Lesion_Volume") %in% colnames(df))) {
                        
                        # Summarize lesion volume by region
                        lesion_summary <- df %>%
                                filter(Region %in% c("Periventricular", "Juxtacortical", "Subcortical", "Infratentorial")) %>%
                                group_by(Region) %>%
                                summarise(Lesion_Volume = sum(Lesion_Volume, na.rm = TRUE)) %>%
                                ungroup() %>%
                                spread(key = Region, value = Lesion_Volume, fill = 0)
                        
                        # Compute total lesion statistics
                        num_lesions <- sum(df$Num_Lesions, na.rm = TRUE)
                        num_vox <- sum(df$Num_Vox, na.rm = TRUE)
                        total_lesion_volume <- sum(df$Lesion_Volume, na.rm = TRUE)
                        
                        # Create a new row with compiled data
                        new_row <- data.frame(
                                Subject_ID = subject_id,
                                Periventricular = lesion_summary$Periventricular,
                                Juxtacortical = lesion_summary$Juxtacortical,
                                Subcortical = lesion_summary$Subcortical,
                                Infratentorial = lesion_summary$Infratentorial,
                                Num_Lesions = num_lesions,
                                Num_Vox = num_vox,
                                Lesion_Volume = total_lesion_volume,
                                stringsAsFactors = FALSE
                        )
                        
                        # Bind the new row to the compiled data frame
                        compiled_data <- bind_rows(compiled_data, new_row)
                }
        }
}

# Define the output file path
output_file <- "/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/LSTAI_Y4Y5/compiled_lesion_stats_Y4Y5.csv"

# Write the compiled data to a CSV file
write.csv(compiled_data, output_file, row.names = FALSE)

# Print a message
cat("Compiled data saved to", output_file, "\n")
