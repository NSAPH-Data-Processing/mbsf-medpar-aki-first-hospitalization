library(fst)
library(tibble)
library(readr)
library(dplyr)

arg <- (commandArgs(TRUE))
year_ <- 2000 + strtoi(arg[1])

# read MEDPAR
path <- "/nfs/nsaph_ci3/ci3_health_data/medicare/gen_admission/1999_2016/targeted_conditions/cache_data/admissions_by_year/admissions_"
filename <- paste(path,  year_, ".fst", sep="")
medpar <- read_fst(filename, columns = c("QID","AGE","SEX","RACE","ADATE","DDATE",
                                             "YEAR","zipcode_R","Dual","DIAG1","DIAG2",
                                             "DIAG3","DIAG4","DIAG5","DIAG6","DIAG7",
                                             "DIAG8","DIAG9","DIAG10"))

# rename cols for merging
names(medpar)[names(medpar) == 'QID'] <- 'qid'
names(medpar)[names(medpar) == 'YEAR'] <- 'year'
names(medpar)[names(medpar) == 'zipcode_R'] <- 'ZIP'

# read FFS IDs
filename <- paste("data/ffs/ffs_ids_", year_, ".csv")
filename <- gsub(" ", "", filename)
ffs <- read.csv(filename) #, nrows=9000)

# cut MEDPAR to keep only FFS
medpar <- medpar %>%
      filter(qid %in% ffs$x)

rm(ffs)
gc()
# add follow_up year
follow_up_path <- paste("/nfs/nsaph_ci3/scratch/jan2021_whanhee_cache/follow_up/follow_up_year_", year_, ".fst", sep="")
follow_up_path <- gsub(" ", "", follow_up_path)
follow_up_year <- read_fst(follow_up_path, columns = c("qid",
                                                     "year",
                                                     "follow_up"))
print("Read follow_up data")
medpar <- merge(medpar, follow_up_year, by = c("qid", "year"))
print("Merged follow_up data")
rm(follow_up_year)
gc()

# add entry_age
entry_age <- read.fst("/nfs/nsaph_ci3/scratch/jan2021_whanhee_cache/entry_age/medicare_entry_age.fst", as.data.table = T)
medpar <- merge(medpar, entry_age, by = "qid")
print("Merged entry_age data")
rm(entry_age)
gc()

# save CSV
names(medpar)[names(medpar) == 'qid'] <- 'QID'
names(medpar)[names(medpar) == 'year'] <- 'YEAR'
# write.csv.gz(x, file, ...
outpath = gsub(" ", "", paste("data/medpar/medpar_", year_, ".csv.gz", sep=""))
write.csv(medpar, outpath, row.names = FALSE)
print("Saved file")

