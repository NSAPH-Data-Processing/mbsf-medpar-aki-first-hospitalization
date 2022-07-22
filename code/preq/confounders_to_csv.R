library(fst)

path = "data/merged_confounders/confounders/merged_confounders_"

arg <- (commandArgs(TRUE))
year_ <- 2000 + strtoi(arg[1])

filename <- paste(path,  year_, ".fst", sep="")
filename <- gsub(" ", "", filename)
print(filename)
df <- read_fst(filename) 

outfile <- gsub(" ", "", paste("data/merged_confounders_", year_, ".csv"))
write.csv(df,outfile)

