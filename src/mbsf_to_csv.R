library(fst)
library(tibble)
library(dplyr)

# get process number from cmd
arg <- (commandArgs(TRUE))
year_ <- 2000 + strtoi(arg[1])

# get MBSF
path <- "/nfs/nsaph_ci3/ci3_health_data/medicare/mortality/1999_2016/wu/cache_data/merged_by_year_v2/confounder_exposure_merged_nodups_health_"

filename <- paste(path,  year_, ".fst", sep="")
filename <- gsub(" ", "", filename)
print(filename)
denom_data <- read_fst(filename, columns = c("qid",
                                              "zip",
                                              "race",
                                              "sex",
                                              "dual",
                                              "hmo_mo"))
# big cut on hmo_mo to select only ffs
denom_data <- filter(denom_data, hmo_mo==0)

# save unique FFS benes for MedPar cut
ffs <- unique(denom_data$qid)
ffspath <- gsub(" ", "", paste("data/ffs/ffs_ids_", year_, ".csv", sep=""))
write.csv(ffs, ffspath, row.names = FALSE)
rm(ffs)
gc()
###

entry_age <- read.fst("/nfs/nsaph_ci3/scratch/jan2021_whanhee_cache/entry_age/medicare_entry_age.fst", as.data.table = T) # to=100, 
#colnames(entry_age)
#names(entry_age)

follow_up_path <- paste("/nfs/nsaph_ci3/scratch/jan2021_whanhee_cache/follow_up/follow_up_year_", year_, ".fst", sep="")
follow_up_path <- gsub(" ", "", follow_up_path)
follow_up_year <- read_fst(follow_up_path, columns = c("qid",
                                                     "year",
                                                     "follow_up"))
print("Read follow_up data")
# add year for merging
denom_data$year = year_

denom_data <- merge(denom_data, follow_up_year, by = c("qid", "year"))
print("Merged follow_up data")

denom_data <- merge(denom_data, entry_age, by = "qid")
print("Merged entry_age data")

group = denom_data %>% 
   group_by(year, zip, race, sex, dual,follow_up, entry_age_group) %>% 
   summarize(ids = paste(sort(unique(qid)),collapse=", ")) %>%
   ungroup()

outpath = gsub(" ", "", paste("data/denom/denom_", year_, ".csv", sep=""))
write.csv(group,outpath, row.names = FALSE)
gc()
print("Saved file")





