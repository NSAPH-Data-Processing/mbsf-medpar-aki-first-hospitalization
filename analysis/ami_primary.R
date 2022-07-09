### Prior to AKI ###
#library(survival)
#library(mgcv)
#library(doParallel)
library(gnm)


### 5. AMI Primary / AKI Secondary ###
alldata<-readRDS("alldata_first_hos_aki.rds")
alldata$pct_hispanic<-1-c(alldata$pct_asian+alldata$pct_blk+alldata$pct_native+alldata$pct_white)
alldata = subset(alldata, select=c('ami_primary_aki_secondary_first_hosp', 
                                   'ami_primary_aki_secondary_first_hosp_denom', 
                                   'pm25.current_year', 'ozone_summer.current_year', 'no2.current_year',
                                   'year', 'region', 'poverty', 'popdensity', 'medianhousevalue', 
                                   'pct_blk', 'pct_hispanic', 'medhouseholdincome', 'pct_owner_occ', 
                                   'education', 'smoke_rate', 'mean_bmi', 'race', 'entry_age_group', 'follow_up', 
                                   'sex', 'dual', 'zip'))
alldata = subset(alldata, ami_primary_aki_secondary_first_hosp_denom >0)
### PM2.5 ###
model<-gnm(ami_primary_aki_secondary_first_hosp~pm25.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(ami_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_pm_amiprimary<-model$coefficient[1]
write.csv(coef_aki_pm_amiprimary,"results/point_aki_pm25_amiprimary.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample & ami_primary_aki_secondary_first_hosp_denom>0)
    
    model<-gnm(ami_primary_aki_secondary_first_hosp~pm25.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(ami_primary_aki_secondary_first_hosp_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"), na.action=na.exclude)
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_pm_amiprimary<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_pm_amiprimary,"results/se_aki_pm25_amiprimary.csv")

### Summer Ozone ###
model<-gnm(ami_primary_aki_secondary_first_hosp~ozone_summer.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(ami_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_o3_amiprimary<-model$coefficient[1]
write.csv(coef_aki_o3_amiprimary,"results/point_aki_o3_amiprimary.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample & ami_primary_aki_secondary_first_hosp_denom>0)
    
    model<-gnm(ami_primary_aki_secondary_first_hosp~ozone_summer.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(ami_primary_aki_secondary_first_hosp_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"), na.action=na.exclude)
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_o3_amiprimary<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_o3_amiprimary,"results/se_aki_o3_amiprimary.csv")

### NO2 ###
model<-gnm(ami_primary_aki_secondary_first_hosp~no2.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(ami_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_no2_amiprimary<-model$coefficient[1]
write.csv(coef_aki_no2_amiprimary,"results/point_aki_no2_amiprimary.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample & ami_primary_aki_secondary_first_hosp_denom>0)
    
    model<-gnm(ami_primary_aki_secondary_first_hosp~no2.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(ami_primary_aki_secondary_first_hosp_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"))
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_no2_amiprimary<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_no2_amiprimary,"results/se_aki_no2_amiprimary.csv")