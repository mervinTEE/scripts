library(tidyverse)
library(fs)

# Paths
base_dir <- "/mnt/hdd/MT/NEURO_BMC/NEURO_ASL/derivatives/ExploreASL"
out_dir  <- "/mnt/hdd/MT/NEURO_BMC/NEURO_ASL/derivatives/ExploreASL_Grp"

# Read CSV (adjust filename)
meta <- read_csv("/mnt/hdd/MT/NEURO_BMC/NEURO_ASL/derivatives/ExploreASL_Grp/fulldf_with_zscore_opt1_opt2_16sept.csv") %>%
        filter(study=="NEURO-BMC") %>% 
        mutate(
                sub_folder = paste0("sub-", sprintf("%03d", as.numeric(gsub("NEURO_", "", id))), "_1"),
                # map gender
                sex_label = gender_0m_1f,
                # map age bins
                age_bin = case_when(
                        age_int >= 30 & age_int <= 40 ~ "30_40",
                        age_int >= 41 & age_int <= 50 ~ "41_50",
                        age_int >= 51 & age_int <= 60 ~ "51_60",
                        age_int >= 61 & age_int <= 70 ~ "61_70",
                        age_int >= 71 & age_int <= 90 ~ "71_90",
                        TRUE ~ "other"
                )
        )

# Ensure output dirs exist
dir_create(file.path(out_dir, "Male_Female/Male"))
dir_create(file.path(out_dir, "Male_Female/Female"))
dir_create(file.path(out_dir, "Age_Int/30_40"))
dir_create(file.path(out_dir, "Age_Int/41_50"))
dir_create(file.path(out_dir, "Age_Int/51_60"))
dir_create(file.path(out_dir, "Age_Int/61_70"))
dir_create(file.path(out_dir, "Age_Int/71_90"))

# Loop through subjects
for (i in 1:nrow(meta)) {
        sub <- meta$sub_folder[i]
        sex <- meta$sex_label[i]
        agebin <- meta$age_bin[i]
        
        tex <- file.path(base_dir, sub, "ASL_2/Tex.nii.gz")
        att <- file.path(base_dir, sub, "ASL_2/ATT.nii.gz")
        cbf <- file.path(base_dir, sub, "ASL_1/CBF.nii.gz")
        
        # Define destination dirs
        sex_dir <- file.path(out_dir, "Male_Female", sex)
        age_dir <- file.path(out_dir, "Age_Int", agebin)
        
        dir_create(sex_dir)
        dir_create(age_dir)
        
        # Copy with unique subject-specific filenames
        file_copy(tex, file.path(sex_dir, paste0(sub, "_Tex.nii.gz")), overwrite = TRUE)
        file_copy(att, file.path(sex_dir, paste0(sub, "_ATT.nii.gz")), overwrite = TRUE)
        file_copy(cbf, file.path(sex_dir, paste0(sub, "_CBF.nii.gz")), overwrite = TRUE)
        
        file_copy(tex, file.path(age_dir, paste0(sub, "_Tex.nii.gz")), overwrite = TRUE)
        file_copy(att, file.path(age_dir, paste0(sub, "_ATT.nii.gz")), overwrite = TRUE)
        file_copy(cbf, file.path(age_dir, paste0(sub, "_CBF.nii.gz")), overwrite = TRUE)
}
