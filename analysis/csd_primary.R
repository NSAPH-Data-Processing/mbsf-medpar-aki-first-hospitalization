#library(survival)
#library(mgcv)
#library(doParallel)
library(gnm)


### 9. CSD Primary / AKI Secondary ###
alldata<-readRDS("alldata_first_hos_aki.rds")
alldata$pct_hispanic<-1-c(alldata$pct_asian+alldata$pct_blk+alldata$pct_native+alldata$pct_white)
alldata = subset(alldata, select=c('csd_primary_aki_secondary_first_hosp', 
                                   'csd_primary_aki_secondary_first_hosp_denom', 
                                   'pm25.current_year', 'ozone_summer.current_year', 'no2.current_year',
                                   'year', 'region', 'poverty', 'popdensity', 'medianhousevalue', 
                                   'pct_blk', 'pct_hispanic', 'medhouseholdincome', 'pct_owner_occ', 
                                   'education', 'smoke_rate', 'mean_bmi', 'race', 'entry_age_group', 'follow_up', 
                                   'sex', 'dual', 'zip'))
alldata = subset(alldata, csd_primary_aki_secondary_first_hosp_denom >0)
### PM2.5 ###
model<-gnm(csd_primary_aki_secondary_first_hosp~pm25.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(csd_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_pm_csdprimary<-model$coefficient[1]
write.csv(coef_aki_pm_csdprimary,"results/point_aki_pm25_csdprimary.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample & csd_primary_aki_secondary_first_hosp_denom>0)
    
    model<-gnm(csd_primary_aki_secondary_first_hosp~pm25.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(csd_primary_aki_secondary_first_hosp_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"))
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_pm_csdprimary<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_pm_csdprimary,"results/se_aki_pm25_csdprimary.csv")

### Summer Ozone ###
model<-gnm(csd_primary_aki_secondary_first_hosp~ozone_summer.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(csd_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_o3_csdprimary<-model$coefficient[1]
write.csv(coef_aki_o3_csdprimary,"results/point_aki_o3_csdprimary.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample & csd_primary_aki_secondary_first_hosp_denom>0)
    
    model<-gnm(csd_primary_aki_secondary_first_hosp~ozone_summer.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(csd_primary_aki_secondary_first_hosp_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"))
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_o3_csdprimary<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_o3_csdprimary,"results/se_aki_o3_csdprimary.csv")

### NO2 ###
model<-gnm(csd_primary_aki_secondary_first_hosp~no2.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(csd_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_no2_csdprimary<-model$coefficient[1]
write.csv(coef_aki_no2_csdprimary,"results/point_aki_no2_csdprimary.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample & csd_primary_aki_secondary_first_hosp_denom>0)
    
    model<-gnm(csd_primary_aki_secondary_first_hosp~no2.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(csd_primary_aki_secondary_first_hosp_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"), na.action=na.exclude)
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_no2_csdprimary<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_no2_csdprimary,"results/se_aki_no2_csdprimary.csv")