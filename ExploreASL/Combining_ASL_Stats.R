# Load the required library
library(dplyr)

# Step 1: Get the list of TSV files in the working directory
tsv_files <- list.files(pattern = "*.tsv")  # Assuming all TSV files are in the working directory

# Check if there are any TSV files
if (length(tsv_files) == 0) {
        stop("No TSV files found in the working directory.")
}

# Read the first TSV file as the main dataframe
main_df <- read.delim(tsv_files[1], header = TRUE)

# Step 2: Loop through subsequent TSV files and append columns after column M to the main dataframe
for (i in 2:length(tsv_files)) {
        tsv_file <- tsv_files[i]
        additional_df <- read.delim(tsv_file, header = TRUE)
        additional_cols <- names(additional_df)[-c(1:13)]  # Exclude columns A to M
        main_df <- cbind(main_df, additional_df[, additional_cols])
}

# Step 3: Write the merged dataframe to a CSV file
write.csv(main_df, "merged.csv", row.names = FALSE)
