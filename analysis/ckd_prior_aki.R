### Prior to AKI ###
#library(survival)
#library(mgcv)
#library(doParallel)
library(gnm)

alldata<-readRDS("alldata_first_hos_aki.rds")
alldata$pct_hispanic<-1-c(alldata$pct_asian+alldata$pct_blk+alldata$pct_native+alldata$pct_white)
alldata = subset(alldata, select=c('ckdhosp_prior_aki', 
                                   'ckdhosp_prior_aki_denom', 
        'pm25.current_year', 'ozone_summer.current_year', 'no2.current_year',
        'year', 'region', 'poverty', 'popdensity', 'medianhousevalue', 
        'pct_blk', 'pct_hispanic', 'medhouseholdincome', 'pct_owner_occ', 
        'education', 'smoke_rate', 'mean_bmi', 'race', 'entry_age_group', 'follow_up', 
        'sex', 'dual', 'zip'))


### 1. CKD Prior to AKI ###
### PM2.5 ### 
alldata = subset(alldata, ckdhosp_prior_aki_denom>0)
model<-gnm(ckdhosp_prior_aki~pm25.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(ckdhosp_prior_aki_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata[alldata$ckdhosp_prior_aki_denom>0,],family=poisson(link="log"), na.action=na.exclude)

coef_aki_pm_ckdprior<-model$coefficient[1]
write.csv(coef_aki_pm_ckdprior,"results/point_aki_pm25_ckdprior.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample)
    
    model<-gnm(ckdhosp_prior_aki~pm25.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(ckdhosp_prior_aki_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots[data_boots$ckdhosp_prior_aki_denom >0,],family=poisson(link="log"))
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_pm_ckdprior<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_pm_ckdprior,"results/se_aki_pm25_ckdprior.csv")

### Summer Ozone ###
model<-gnm(ckdhosp_prior_aki~ozone_summer.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(ckdhosp_prior_aki_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata[alldata$ckdhosp_prior_aki_denom>0, ],family=poisson(link="log"), na.action=na.exclude)

coef_aki_o3_ckdprior<-model$coefficient[1]
write.csv(coef_aki_o3_ckdprior,"results/point_aki_o3_ckdprior.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample)
    
    model<-gnm(ckdhosp_prior_aki~ozone_summer.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(ckdhosp_prior_aki_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots[data_boots$ckdhosp_prior_aki_denom>0, ],family=poisson(link="log"), na.action=na.exclude)
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_o3_ckdprior<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_o3_ckdprior,"results/se_aki_o3_ckdprior.csv")

### NO2 ###
model<-gnm(ckdhosp_prior_aki~no2.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(ckdhosp_prior_aki_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata[alldata$ckdhosp_prior_aki_denom >0,],family=poisson(link="log"), na.action=na.exclude)

coef_aki_no2_ckdprior<-model$coefficient[1]
write.csv(coef_aki_no2_ckdprior,"results/point_aki_no2_ckdprior.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample & ckdhosp_prior_aki_denom>0)
    
    model<-gnm(ckdhosp_prior_aki~no2.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(ckdhosp_prior_aki_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"), na.action=na.exclude)
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_no2_ckdprior<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_no2_ckdprior,"results/se_aki_no2_ckdprior.csv")