library(fst)

arg <- (commandArgs(TRUE))
year_ <- 2000 + strtoi(arg[1])

# read MEDPAR
path <- "data/medpar_fst/admissions_by_year/admissions_"



filename <- paste(path,  year_, ".fst", sep="")
filename <- gsub(" ", "", filename)
print(filename)
df <- read_fst(filename) 

outfile <- gsub(" ", "", paste("data/medpar/medpar2_", year_, ".csv"))
write.csv(df,outfile)

