#library(survival)
#library(mgcv)
#library(lme4)
#library(doParallel)
library(gnm)


### 6. HF Primary / AKI Secondary ###
alldata<-readRDS("alldata_first_hos_aki.rds")
alldata$pct_hispanic<-1-c(alldata$pct_asian+alldata$pct_blk+alldata$pct_native+alldata$pct_white)
alldata = subset(alldata, select=c('hf_primary_aki_secondary_first_hosp', 
                                   'hf_primary_aki_secondary_first_hosp_denom', 
                                   'pm25.current_year', 'ozone_summer.current_year', 'no2.current_year',
                                   'year', 'region', 'poverty', 'popdensity', 'medianhousevalue', 
                                   'pct_blk', 'pct_hispanic', 'medhouseholdincome', 'pct_owner_occ', 
                                   'education', 'smoke_rate', 'mean_bmi', 'race', 'entry_age_group', 'follow_up', 
                                   'sex', 'dual', 'zip'))
alldata = subset(alldata, hf_primary_aki_secondary_first_hosp_denom >0)
### PM2.5 ###
model<-gnm(hf_primary_aki_secondary_first_hosp~pm25.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(hf_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata[alldata$hf_primary_aki_secondary_first_hosp_denom>0,],family=poisson(link="log"), na.action=na.exclude)

coef_aki_pm_hfprimary<-model$coefficient[1]
write.csv(coef_aki_pm_hfprimary,"results/point_aki_pm25_hfprimary.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample & hf_primary_aki_secondary_first_hosp_denom>0)
    
    model<-gnm(hf_primary_aki_secondary_first_hosp~pm25.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(hf_primary_aki_secondary_first_hosp_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"), na.action=na.exclude)
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_pm_hfprimary<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_pm_hfprimary,"results/se_aki_pm25_hfprimary.csv")

### Summer Ozone ###
model<-gnm(hf_primary_aki_secondary_first_hosp~ozone_summer.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(hf_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_o3_hfprimary<-model$coefficient[1]
write.csv(coef_aki_o3_hfprimary,"results/point_aki_o3_hfprimary.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample &hf_primary_aki_secondary_first_hosp_denom>0 )
    
    model<-gnm(hf_primary_aki_secondary_first_hosp~ozone_summer.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(hf_primary_aki_secondary_first_hosp_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"), na.action=na.exclude)
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_o3_hfprimary<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_o3_hfprimary,"results/se_aki_o3_hfprimary.csv")

### NO2 ###
model<-gnm(hf_primary_aki_secondary_first_hosp~no2.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(hf_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_no2_hfprimary<-model$coefficient[1]
write.csv(coef_aki_no2_hfprimary,"results/point_aki_no2_hfprimary.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample & hf_primary_aki_secondary_first_hosp_denom>0)
    
    model<-gnm(hf_primary_aki_secondary_first_hosp~no2.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(hf_primary_aki_secondary_first_hosp_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"), na.action=na.exclude)
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_no2_hfprimary<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_no2_hfprimary,"results/se_aki_no2_hfprimary.csv")