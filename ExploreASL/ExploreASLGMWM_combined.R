library(pacman)
p_load(dplyr, tidyverse)
# dir <- "C:/Users/Mervin/Desktop/Analysis/NEURO-BMC/Determinants/Determinants/Data/ASL"
# 
# setwd("C:/Users/Mervin/Desktop/Analysis/NEURO-BMC/Determinants/Determinants/Data/ASL")

dir <- "/home/admin/Desktop/Analysis/NEURO_determinants/Data/combined/"

setwd("/home/admin/Desktop/Analysis/NEURO_determinants/Data/combined/")


# CBF -------------------------------------------------------------------------------------------------------------
GMCBF_PVC0 <- "mean_qCBF_StandardSpace_TotalGM.*PVC0\\.tsv"
WMCBF_PVC0 <- "mean_qCBF_StandardSpace_DeepWM.*PVC0\\.tsv"
GMCBF_PVC2 <- "mean_qCBF_StandardSpace_TotalGM.*PVC2\\.tsv"
WMCBF_PVC2 <- "mean_qCBF_StandardSpace_DeepWM.*PVC2\\.tsv"

# Listing files in directory
files <- list.files(dir, pattern = "\\.tsv$")

# Looking for files that match the patterns
GM_PVC0_cbffile <- grep(GMCBF_PVC0, files, value = TRUE)
WM_PVC0_cbffile <- grep(WMCBF_PVC0, files, value = TRUE)
GM_PVC2_cbffile <- grep(GMCBF_PVC2, files, value = TRUE)
WM_PVC2_cbffile <- grep(WMCBF_PVC2, files, value = TRUE)

# Loading data from the matching files into separate data frames (df)
GM_pvc0_cbfraw <- do.call(rbind, lapply(GM_PVC0_cbffile, read.table, sep = "\t", header = TRUE))
WM_pvc0_cbfraw <- do.call(rbind, lapply(WM_PVC0_cbffile, read.table, sep = "\t", header = TRUE)) %>% select(participant_id, session, DeepWM_B, DeepWM_L, DeepWM_R)
GM_pvc2_cbfraw <- do.call(rbind, lapply(GM_PVC2_cbffile, read.table, sep = "\t", header = TRUE))
WM_pvc2_cbfraw <- do.call(rbind, lapply(WM_PVC2_cbffile, read.table, sep = "\t", header = TRUE)) %>% select(participant_id, session, DeepWM_B, DeepWM_L, DeepWM_R)

# Perform the left join on GM and WM data frames
GMWM_pvc0_cbfraw <- left_join(GM_pvc0_cbfraw, WM_pvc0_cbfraw, by = c("participant_id", "session"))
GMWM_pvc2_cbfraw <- left_join(GM_pvc2_cbfraw, WM_pvc2_cbfraw, by = c("participant_id", "session"))


# Define the suffix and prefix based on file name conditions(PVC0)
filelist<- GM_PVC0_cbffile
suffix <- ifelse(grepl("PVC0", filelist), "_PVC0", ifelse(grepl("PVC2", filelist), "_PVC2", ""))
prefix <- ifelse(grepl("CBF", filelist), "cbf_", ifelse(grepl("ATT", filelist), "att_", ifelse(grepl("Tex", filelist), "tex_", "")))

GMWM_pvc0_cbfraw <- GMWM_pvc0_cbfraw %>%
        rename_with(~ gsub("TotalGM", paste0("TotalGM", suffix), .), .cols = contains("TotalGM")) %>%
        rename_with(~ gsub("DeepWM", paste0("DeepWM", suffix), .), .cols = contains("DeepWM")) %>%
        rename_with(~ gsub("^", prefix, .), .cols = matches("TotalGM|DeepWM"))
GMWM_pvc0_cbfraw


# Define the suffix and prefix based on file name conditions(PVC2)
filelist<- GM_PVC2_cbffile
suffix <- ifelse(grepl("PVC0", filelist), "_PVC0", ifelse(grepl("PVC2", filelist), "_PVC2", ""))
prefix <- ifelse(grepl("CBF", filelist), "CBF_", ifelse(grepl("ATT", filelist), "ATT_", ifelse(grepl("Tex", filelist), "Tex_", "")))

GMWM_pvc2_cbfraw <- GMWM_pvc2_cbfraw %>%
        rename_with(~ gsub("TotalGM", paste0("TotalGM", suffix), .), .cols = contains("TotalGM")) %>%
        rename_with(~ gsub("DeepWM", paste0("DeepWM", suffix), .), .cols = contains("DeepWM")) %>%
        rename_with(~ gsub("^", prefix, .), .cols = matches("TotalGM|DeepWM"))
GMWM_pvc2_cbfraw

combinedcbf<-left_join(GMWM_pvc0_cbfraw, GMWM_pvc2_cbfraw, by =  c("participant_id", "session", "LongitudinalTimePoint", "SubjectNList", "Site",
                                                                   "GM_vol", "WM_vol", "CSF_vol", "GM_ICVRatio", "GMWM_ICVRatio",
                                                                   "WMH_vol", "WMH_count", "MeanMotion"))

GMWM_pvc2_cbfraw

# ATT -------------------------------------------------------------------------------------------------------------
GMATT_PVC0 <- "mean_ATT_StandardSpace_TotalGM.*PVC0\\.tsv"
WMATT_PVC0 <- "mean_ATT_StandardSpace_DeepWM.*PVC0\\.tsv"
GMATT_PVC2 <- "mean_ATT_StandardSpace_TotalGM.*PVC2\\.tsv"
WMATT_PVC2 <- "mean_ATT_StandardSpace_DeepWM.*PVC2\\.tsv"

GM_PVC0_attfile <- grep(GMATT_PVC0, files, value = TRUE)
WM_PVC0_attfile <- grep(WMATT_PVC0, files, value = TRUE)
GM_PVC2_attfile <- grep(GMATT_PVC2, files, value = TRUE)
WM_PVC2_attfile <- grep(WMATT_PVC2, files, value = TRUE)


# Loading data from the matching files into separate data frames (df)
GM_pvc0_attraw <- do.call(rbind, lapply(GM_PVC0_attfile, read.table, sep = "\t", header = TRUE))
WM_pvc0_attraw <- do.call(rbind, lapply(WM_PVC0_attfile, read.table, sep = "\t", header = TRUE)) %>% select(participant_id, session, DeepWM_B, DeepWM_L, DeepWM_R)
GM_pvc2_attraw <- do.call(rbind, lapply(GM_PVC2_attfile, read.table, sep = "\t", header = TRUE))
WM_pvc2_attraw <- do.call(rbind, lapply(WM_PVC2_attfile, read.table, sep = "\t", header = TRUE)) %>% select(participant_id, session, DeepWM_B, DeepWM_L, DeepWM_R)

# Perform the left join on GM and WM data frames
GMWM_attraw_pvc0 <- left_join(GM_pvc0_attraw, WM_pvc0_attraw, by = c("participant_id", "session"))
GMWM_attraw_pvc2 <- left_join(GM_pvc2_attraw, WM_pvc2_attraw, by = c("participant_id", "session"))


# Define the suffix and prefix based on file name conditions (PVC0)
filelist<- GM_PVC0_attfile
suffix <- ifelse(grepl("PVC0", filelist), "_PVC0", ifelse(grepl("PVC2", filelist), "_PVC2", ""))
prefix <- ifelse(grepl("CBF", filelist), "cbf_", ifelse(grepl("ATT", filelist), "att_", ifelse(grepl("Tex", filelist), "tex_", "")))


GMWM_attraw_pvc0 <- GMWM_attraw_pvc0 %>%
        rename_with(~ gsub("TotalGM", paste0("TotalGM", suffix), .), .cols = contains("TotalGM")) %>%
        rename_with(~ gsub("DeepWM", paste0("DeepWM", suffix), .), .cols = contains("DeepWM")) %>%
        rename_with(~ gsub("^", prefix, .), .cols = matches("TotalGM|DeepWM"))
GMWM_attraw_pvc0


# Define the suffix and prefix based on file name conditions (PVC0)
filelist<- GM_PVC2_attfile
suffix <- ifelse(grepl("PVC0", filelist), "_PVC0", ifelse(grepl("PVC2", filelist), "_PVC2", ""))
prefix <- ifelse(grepl("CBF", filelist), "cbf_", ifelse(grepl("ATT", filelist), "att_", ifelse(grepl("Tex", filelist), "tex_", "")))


GMWM_attraw_pvc2 <- GMWM_attraw_pvc2 %>%
        rename_with(~ gsub("TotalGM", paste0("TotalGM", suffix), .), .cols = contains("TotalGM")) %>%
        rename_with(~ gsub("DeepWM", paste0("DeepWM", suffix), .), .cols = contains("DeepWM")) %>%
        rename_with(~ gsub("^", prefix, .), .cols = matches("TotalGM|DeepWM"))


left_join(GMWM_attraw_pvc0, GMWM_attraw_pvc2, by =  c("participant_id", "session", "LongitudinalTimePoint", "SubjectNList", "Site",
        "GM_vol", "WM_vol", "CSF_vol", "GM_ICVRatio", "GMWM_ICVRatio",
        "WMH_vol", "WMH_count", "MeanMotion"))

combinedatt<-left_join(GMWM_attraw_pvc0, GMWM_attraw_pvc2, by =  c("participant_id", "session", "LongitudinalTimePoint", "SubjectNList", "Site",
                                                          "GM_vol", "WM_vol", "CSF_vol", "GM_ICVRatio", "GMWM_ICVRatio",
                                                          "WMH_vol", "WMH_count", "MeanMotion"))



# TEX -------------------------------------------------------------------------------------------------------------

GMTEX_PVC0 <- "mean_Tex_StandardSpace_TotalGM.*PVC0\\.tsv"
WMTEX_PVC0 <- "mean_Tex_StandardSpace_DeepWM.*PVC0\\.tsv"
GMTEX_PVC2 <- "mean_Tex_StandardSpace_TotalGM.*PVC2\\.tsv"
WMTEX_PVC2 <- "mean_Tex_StandardSpace_DeepWM.*PVC2\\.tsv"

# Listing files in directory
files <- list.files(dir, pattern = "\\.tsv$")

# Looking for files that match the patterns
GM_PVC0_texfile <- grep(GMTEX_PVC0, files, value = TRUE)
WM_PVC0_texfile <- grep(WMTEX_PVC0, files, value = TRUE)
GM_PVC2_texfile <- grep(GMTEX_PVC2, files, value = TRUE)
WM_PVC2_texfile <- grep(WMTEX_PVC2, files, value = TRUE)

# Loading data from the matching files into separate data frames (df)
GM_pvc0_texraw <- do.call(rbind, lapply(GM_PVC0_texfile, read.table, sep = "\t", header = TRUE))
WM_pvc0_texraw <- do.call(rbind, lapply(WM_PVC0_texfile, read.table, sep = "\t", header = TRUE)) %>% select(participant_id, session, DeepWM_B, DeepWM_L, DeepWM_R)
GM_pvc2_texraw <- do.call(rbind, lapply(GM_PVC2_texfile, read.table, sep = "\t", header = TRUE))
WM_pvc2_texraw <- do.call(rbind, lapply(WM_PVC2_texfile, read.table, sep = "\t", header = TRUE)) %>% select(participant_id, session, DeepWM_B, DeepWM_L, DeepWM_R)

# Perform the left join on GM and WM data frames
GMWM_pvc0_texraw <- left_join(GM_pvc0_texraw, WM_pvc0_texraw, by = c("participant_id", "session"))
GMWM_pvc2_texraw <- left_join(GM_pvc2_texraw, WM_pvc2_texraw, by = c("participant_id", "session"))


# Define the suffix and prefix based on file name conditions(PVC0)
filelist<- GM_PVC0_texfile
suffix <- ifelse(grepl("PVC0", filelist), "_PVC0", ifelse(grepl("PVC2", filelist), "_PVC2", ""))
prefix <- ifelse(grepl("CBF", filelist), "cbf_", ifelse(grepl("ATT", filelist), "att_", ifelse(grepl("Tex", filelist), "tex_", "")))

GMWM_pvc0_texraw <- GMWM_pvc0_texraw %>%
        rename_with(~ gsub("TotalGM", paste0("TotalGM", suffix), .), .cols = contains("TotalGM")) %>%
        rename_with(~ gsub("DeepWM", paste0("DeepWM", suffix), .), .cols = contains("DeepWM")) %>%
        rename_with(~ gsub("^", prefix, .), .cols = matches("TotalGM|DeepWM"))
GMWM_pvc0_texraw


# Define the suffix and prefix based on file name conditions(PVC2)
filelist<- GM_PVC2_texfile
suffix <- ifelse(grepl("PVC0", filelist), "_PVC0", ifelse(grepl("PVC2", filelist), "_PVC2", ""))
prefix <- ifelse(grepl("CBF", filelist), "cbf_", ifelse(grepl("ATT", filelist), "att_", ifelse(grepl("Tex", filelist), "tex_", "")))

GMWM_pvc2_texraw <- GMWM_pvc2_texraw %>%
        rename_with(~ gsub("TotalGM", paste0("TotalGM", suffix), .), .cols = contains("TotalGM")) %>%
        rename_with(~ gsub("DeepWM", paste0("DeepWM", suffix), .), .cols = contains("DeepWM")) %>%
        rename_with(~ gsub("^", prefix, .), .cols = matches("TotalGM|DeepWM"))
GMWM_pvc2_texraw

combinedtex<-left_join(GMWM_pvc0_texraw, GMWM_pvc2_texraw, by =  c("participant_id", "session", "LongitudinalTimePoint", "SubjectNList", "Site",
                                                                   "GM_vol", "WM_vol", "CSF_vol", "GM_ICVRatio", "GMWM_ICVRatio",
                                                                   "WMH_vol", "WMH_count", "MeanMotion"))

# M0 --------------------------------------------------------------------------------------------------------------
GMM0_PVC0 <- "mean_M0_StandardSpace_TotalGM.*PVC0\\.tsv"
WMM0_PVC0 <- "mean_M0_StandardSpace_DeepWM.*PVC0\\.tsv"
GMM0_PVC2 <- "mean_M0_StandardSpace_TotalGM.*PVC2\\.tsv"
WMM0_PVC2 <- "mean_M0_StandardSpace_DeepWM.*PVC2\\.tsv"

# Listing files in directory
files <- list.files(dir, pattern = "\\.tsv$")

# Looking for files that match the patterns
GM_PVC0_M0file <- grep(GMM0_PVC0, files, value = TRUE)
WM_PVC0_M0file <- grep(WMM0_PVC0, files, value = TRUE)
GM_PVC2_M0file <- grep(GMM0_PVC2, files, value = TRUE)
WM_PVC2_M0file <- grep(WMM0_PVC2, files, value = TRUE)

# Loading data from the matching files into separate data frames (df)
GM_pvc0_M0raw <- do.call(rbind, lapply(GM_PVC0_M0file, read.table, sep = "\t", header = TRUE))
WM_pvc0_M0raw <- do.call(rbind, lapply(WM_PVC0_M0file, read.table, sep = "\t", header = TRUE)) %>% select(participant_id, session, DeepWM_B, DeepWM_L, DeepWM_R)
GM_pvc2_M0raw <- do.call(rbind, lapply(GM_PVC2_M0file, read.table, sep = "\t", header = TRUE))
WM_pvc2_M0raw <- do.call(rbind, lapply(WM_PVC2_M0file, read.table, sep = "\t", header = TRUE)) %>% select(participant_id, session, DeepWM_B, DeepWM_L, DeepWM_R)

# Perform the left join on GM and WM data frames
GMWM_pvc0_M0raw <- left_join(GM_pvc0_M0raw, WM_pvc0_M0raw, by = c("participant_id", "session"))
GMWM_pvc2_M0raw <- left_join(GM_pvc2_M0raw, WM_pvc2_M0raw, by = c("participant_id", "session"))


# Define the suffix and prefix based on file name conditions(PVC0)
filelist<- GM_PVC0_M0file
suffix <- ifelse(grepl("PVC0", filelist), "_PVC0", ifelse(grepl("PVC2", filelist), "_PVC2", ""))
prefix <- ifelse(grepl("CBF", filelist), "cbf_", ifelse(grepl("ATT", filelist), "att_", ifelse(grepl("Tex", filelist), "tex_", ifelse(grepl("M0", filelist), "m0_", ""))))

GMWM_pvc0_M0raw <- GMWM_pvc0_M0raw %>%
        rename_with(~ gsub("TotalGM", paste0("TotalGM", suffix), .), .cols = contains("TotalGM")) %>%
        rename_with(~ gsub("DeepWM", paste0("DeepWM", suffix), .), .cols = contains("DeepWM")) %>%
        rename_with(~ gsub("^", prefix, .), .cols = matches("TotalGM|DeepWM"))
GMWM_pvc0_M0raw


# Define the suffix and prefix based on file name conditions(PVC2)
filelist<- GM_PVC2_M0file
suffix <- ifelse(grepl("PVC0", filelist), "_PVC0", ifelse(grepl("PVC2", filelist), "_PVC2", ""))
prefix <- ifelse(grepl("CBF", filelist), "cbf_", ifelse(grepl("ATT", filelist), "att_", ifelse(grepl("Tex", filelist), "tex_", ifelse(grepl("M0", filelist), "m0_", ""))))

GMWM_pvc2_M0raw <- GMWM_pvc2_M0raw %>%
        rename_with(~ gsub("TotalGM", paste0("TotalGM", suffix), .), .cols = contains("TotalGM")) %>%
        rename_with(~ gsub("DeepWM", paste0("DeepWM", suffix), .), .cols = contains("DeepWM")) %>%
        rename_with(~ gsub("^", prefix, .), .cols = matches("TotalGM|DeepWM"))
GMWM_pvc2_M0raw

combinedm0<-left_join(GMWM_pvc0_M0raw, GMWM_pvc2_M0raw, by =  c("participant_id", "session", "LongitudinalTimePoint", "SubjectNList", "Site",
                                                                   "GM_vol", "WM_vol", "CSF_vol", "GM_ICVRatio", "GMWM_ICVRatio",
                                                                   "WMH_vol", "WMH_count", "MeanMotion"))



# Combing all Data  -----------------------------------------------------------------------------------------------
combinedcbfatt<-left_join(combinedcbf, combinedatt, by =  c("participant_id", "session", "LongitudinalTimePoint", "SubjectNList", "Site",
                                                                   "GM_vol", "WM_vol", "CSF_vol", "GM_ICVRatio", "GMWM_ICVRatio",
                                                                   "WMH_vol", "WMH_count", "MeanMotion"))
textemp<- combinedtex %>% select(participant_id, session, contains("Total"), contains("Deep"))
m0temp<- combinedm0 %>% select(participant_id, session, contains("Total"), contains("Deep"))

combinedcbfatttex<-left_join(combinedcbfatt, textemp, by =  c("participant_id", "session"))
combinedall<-left_join(combinedcbfatttex, m0temp, by =  c("participant_id", "session"))
combinedall <- combinedall[-1, , drop = FALSE]

names(combinedall)

write.csv(x = combinedall, "CBFATTTEX_values.csv", row.names=FALSE)


