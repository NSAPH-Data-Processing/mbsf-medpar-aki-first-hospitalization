library(fst)

path = "/nfs/nsaph_ci3/scratch/jan2021_whanhee_cache/merged_exposure_confounders/merged_confounders_"

for (year_ in 2000:2016) {
  filename <- paste(path,  year_, ".fst", sep="")
  filename <- gsub(" ", "", filename)
  print(filename)
  df <- read_fst(filename) 
                                    
   outfile <- gsub(" ", "", paste("data/merged_confounders_", year_, ".csv"))
   write.csv(df,outfile)
}

