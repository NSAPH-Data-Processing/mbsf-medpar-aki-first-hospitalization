library(fst)
library(tibble)
library(dplyr)

# get process number from cmd
arg <- (commandArgs(TRUE))
year_ <- 2000 + strtoi(arg[1])

# get MBSF
path <- "data/denom_by_year/confounder_exposure_merged_nodups_health_"
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

entry_age <- read.fst("data/medicare_entry_age/medicare_entry_age.fst", as.data.table = T)  

follow_up_path <- paste("data/years_in_medicare/follow_up_year_", year_, ".fst", sep="")
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

outpath = gsub(" ", "", paste("data/denom/qid_denom_", year_, ".csv", sep=""))

write.csv(denom_data,outpath)

print("Saved file")

