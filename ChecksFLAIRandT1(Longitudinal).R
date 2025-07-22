library(dplyr)
library(stringr)

# Define root directories
roots <- list(
        BL = "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_BL",
        Y2 = "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_Y2",
        Y4Y5 = "/mnt/hdd/MT/HARMY/HARMY_ASL/rawdata_Y4Y5"
)

# Get all unique subject IDs
all_subjects <- unique(unlist(lapply(roots, function(path) {
        dirs <- list.dirs(path, recursive = FALSE)
        basename(dirs[grepl("sub-", basename(dirs))])
})))

# Initialize results list
results <- list()

# Iterate through all subjects
for (subj in all_subjects) {
        found_timepoints <- c()
        flair_and_t1_all_present <- TRUE
        
        for (tp in names(roots)) {
                anat_path <- file.path(roots[[tp]], subj, "anat")
                
                if (dir.exists(anat_path)) {
                        files <- list.files(anat_path, pattern = "\\.nii\\.gz$", full.names = TRUE)
                        flair_present <- any(str_detect(files, "FLAIR"))
                        t1_present <- any(str_detect(files, "T1"))
                        
                        found_timepoints <- c(found_timepoints, tp)
                        
                        if (!(flair_present && t1_present)) {
                                flair_and_t1_all_present <- FALSE
                        }
                }
        }
        
        tp_count <- length(found_timepoints)
        has_all <- ifelse(tp_count == 3, "Yes", "No")
        has_two <- ifelse(tp_count >= 2, "Yes", "No")
        which_two <- ifelse(tp_count == 2, paste(found_timepoints, collapse = " and "), "")
        only_one <- ifelse(tp_count == 1, "Yes", "No")
        only_tp <- ifelse(tp_count == 1, found_timepoints[1], "")
        flair_and_t1 <- ifelse(flair_and_t1_all_present && tp_count > 0, "Yes", "No")
        
        results[[length(results) + 1]] <- data.frame(
                subj_id = subj,
                has_all_timepoints = has_all,
                has_at_least_two_timepoints = has_two,
                which_two_timepoints = which_two,
                only_one_timepoint = only_one,
                only_in_timepoint = only_tp,
                has_flair_and_t1 = flair_and_t1,
                stringsAsFactors = FALSE
        )
}

# Combine and save to CSV
results_df <- bind_rows(results)
write.csv(results_df, "subject_summary.csv", row.names = FALSE)
