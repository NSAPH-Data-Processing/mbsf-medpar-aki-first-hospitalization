library(jsonlite)
library(icd)

#install.packages("devtools", repos='http://cran.rstudio.com')
#library(devtools)
#devtools::install_github("jackwasey/icd")

outcomes <- list()
outcomes[["all_kidney"]] <- list()
outcomes[["all_kidney"]][["icd9"]] <- expand_range("580","599")
outcomes[["all_kidney"]][["icd10"]] <- expand_range("N00","N39")
outcomes[["ckd"]] <- list()
outcomes[["ckd"]][["icd9"]] <- children("585")
outcomes[["ckd"]][["icd10"]] <- children("N18")
outcomes[["aki"]] <- list()
outcomes[["aki"]][["icd9"]] <- children("584")
outcomes[["aki"]][["icd10"]] <- children("N17")
outcomes[["glomerular"]][["icd9"]] <- expand_range("580", "583")
outcomes[["glomerular"]][["icd10"]] <- expand_range("N00", "N08")

# add diabetes 
outcomes[["diabetes"]] <- list()
outcomes[["diabetes"]][["icd9"]] <- children("250") 
outcomes[["diabetes"]][["icd10"]] <- c(children("E08"),children("E09"), children("E10"), children("E11"), children("E12"), children("E13") )

#add co-morbidities
#Circulatory system disease: ICD-9 390-459 / ICD-10 I00-I99
outcomes[["csd"]] <- list()
outcomes[["csd"]][["icd9"]] <- expand_range("390", "459") 
outcomes[["csd"]][["icd10"]] <- expand_range("I00", "I99") 
#Ischemic heart disease: ICD-9 410-414 / ICD-10 I20-I25
outcomes[["ihd"]] <- list()
outcomes[["ihd"]][["icd9"]] <- expand_range("410", "414") 
outcomes[["ihd"]][["icd10"]] <- expand_range("I20", "I25") 
#Pneumonia: ICD-9 480-486 / ICD-10 J12-J18
outcomes[["pneumonia"]] <- list()
outcomes[["pneumonia"]][["icd9"]] <- expand_range("480", "486") 
outcomes[["pneumonia"]][["icd10"]] <- expand_range("J12", "J18") 
#Heart failure: ICD-9 428/ ICD-10 I50
outcomes[["hf"]] <- list()
outcomes[["hf"]][["icd9"]] <- children("428") 
outcomes[["hf"]][["icd10"]] <- children("I50") 
#Acute myocardial infarction: ICD-9 410/ ICD-10 I21
outcomes[["ami"]] <- list()
outcomes[["ami"]][["icd9"]] <- children("410")  
outcomes[["ami"]][["icd10"]] <- children("I21")   
#Cerebrovascular diseases: ICD-9 430-438/ ICD-10 I60-I69
outcomes[["cerd"]] <- list()
outcomes[["cerd"]][["icd9"]] <- expand_range("430", "438")  
outcomes[["cerd"]][["icd10"]] <- expand_range("I60", "I69")   

#Urinary tract infection: ICD-9 599.0 / ICD-10 N39.0
outcomes[["uti"]] <- list()
outcomes[["uti"]][["icd9"]] <- children("599.0")  
outcomes[["uti"]][["icd10"]] <- children("N39.0")   

write_json(toJSON(outcomes), "icd_codes.json")
