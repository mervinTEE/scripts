# Define the base directory where the project structure will be created
# You can set this to a specific path if you prefer
base_dir <- getwd()  # Current working directory

# List of directories to create
directories <- c(
        "Docs",
        "Docs/Manuscript",
        "Data/Raw",
        "Data/Processed",
        "Scripts/1_Fundamental",
        "Scripts/2_Exploratory",
        "Scripts/3_Manuscript",
        "Results/Plots",
        "Results/Tables",
        "Reference",
        "Misc"
)

# Function to create directories
create_directories <- function(base, dirs) {
        for (dir in dirs) {
                path <- file.path(base, dir)
                if (!dir.exists(path)) {
                        dir.create(path, recursive = TRUE)
                        message(paste("Created directory:", path))
                } else {
                        message(paste("Directory already exists:", path))
                }
        }
}

# Create the directories
create_directories(base_dir, directories)

# List of files to create with their respective paths
files <- c(
        "Docs/Manuscript/manuscript.md",
        "Docs/Notebook.txt",
        "Scripts/1_Fundamental/packages_fx_scripts.R",
        "Scripts/2_Exploratory/eda.rmd",
        "Scripts/3_Manuscript/manuscript_analysis.rmd"
)

# Function to create files
create_files <- function(base, file_paths) {
        for (file in file_paths) {
                path <- file.path(base, file)
                if (!file.exists(path)) {
                        file.create(path)
                        message(paste("Created file:", path))
                } else {
                        message(paste("File already exists:", path))
                }
        }
}

# Create the files
create_files(base_dir, files)


# Optional: Print a completion message
rm(list = ls())
message("File structure creation complete!")