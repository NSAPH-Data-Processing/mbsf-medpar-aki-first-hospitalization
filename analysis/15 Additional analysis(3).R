library(devtools)
library(fst)
library(NSAPHutils)
library(parallel)
library(data.table)
library(plyr)

### Data Step ###
alldata<-read.csv("/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/data/final.csv")

#State code
zcta_code<-fread("/nfs/home/S/seh415/shared_space/ci3_exposure/locations/zcta/crosswalk/Zip_to_ZCTA_crosswalk_2015_JSI.csv")
zcta_code$zip<-zcta_code$ZIP
alldata<-merge(alldata,zcta_code,all.x=TRUE,by="zip")

#Region
alldata$region<-ifelse(alldata$STATE %in% c("IL","IN","IA","KS","MI","MN","MO","NE","ND","OH","SD","WI"),"Midwest",
               ifelse(alldata$STATE %in% c("CT","DE","DC","ME","MD","MA","NH","NJ","NY","PA","RI","VT"),"Northeast",
              ifelse(alldata$STATE %in% c("AS","GU","MP","PW","PR","VI","OM"),"Others",
            ifelse(alldata$STATE %in% c("AL","AR","FL","GA","KY","LA","MS","NC","SC","TN","VA","WV"),"Southeast",
          ifelse(alldata$STATE %in% c("AZ","NM","OK","TX"),"Southwest","West")))))
alldata<-subset(alldata,alldata$STATE != "PR")

#Temperature
tempdata<-readRDS("/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_kidney/data/temp/NARR0016_zipcode.rds")
tempdata$year<-as.numeric(substr(tempdata$date,1,4))

annual_temp<-aggregate(x=tempdata$air_temp_2m,by=list(tempdata$zipc,tempdata$year),FUN=mean,na.rm=T)
colnames(annual_temp)<-c("zip","year","temp_annual_k")
annual_temp$temp_annual<-annual_temp$temp_annual_k-273
annual_temp$zip<-as.numeric(annual_temp$zip)

alldata<-merge(alldata,annual_temp,by=c("zip","year"),all.x=TRUE)
saveRDS(alldata,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/data/alldata_first_hos_aki_0016(2).rds")
rm(alldata)


### Prior to AKI ###
library(coxme)
library(survival)
library(mgcv)
library(lme4)
library(doParallel)
library(gnm)

alldata<-readRDS("/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/data/alldata_first_hos_aki_0016(2).rds")
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
write.csv(coef_aki_pm_ckdprior,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/point_aki_pm25_ckdprior.csv")
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
write.csv(aki_se_pm_ckdprior,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/se_aki_pm25_ckdprior.csv")

### Summer Ozone ###
model<-gnm(ckdhosp_prior_aki~ozone_summer.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(ckdhosp_prior_aki_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata[alldata$ckdhosp_prior_aki_denom>0, ],family=poisson(link="log"), na.action=na.exclude)

coef_aki_o3_ckdprior<-model$coefficient[1]
write.csv(coef_aki_o3_ckdprior,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/point_aki_o3_ckdprior.csv")
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
write.csv(aki_se_o3_ckdprior,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/se_aki_o3_ckdprior.csv")

### NO2 ###
model<-gnm(ckdhosp_prior_aki~no2.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(ckdhosp_prior_aki_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata[alldata$ckdhosp_prior_aki_denom >0,],family=poisson(link="log"), na.action=na.exclude)

coef_aki_no2_ckdprior<-model$coefficient[1]
write.csv(coef_aki_no2_ckdprior,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/point_aki_no2_ckdprior.csv")
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
write.csv(aki_se_no2_ckdprior,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/se_aki_no2_ckdprior.csv")


### 2. Diabetes Prior to AKI ###

alldata<-readRDS("/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/data/alldata_first_hos_aki_0016(2).rds")
alldata$pct_hispanic<-1-c(alldata$pct_asian+alldata$pct_blk+alldata$pct_native+alldata$pct_white)
alldata = subset(alldata, select=c('diabetesosp_prior_aki', 
                                   'diabeteshosp_prior_aki_denom', 
                                   'pm25.current_year', 'ozone_summer.current_year', 'no2.current_year',
                                   'year', 'region', 'poverty', 'popdensity', 'medianhousevalue', 
                                   'pct_blk', 'pct_hispanic', 'medhouseholdincome', 'pct_owner_occ', 
                                   'education', 'smoke_rate', 'mean_bmi', 'race', 'entry_age_group', 'follow_up', 
                                   'sex', 'dual', 'zip'))
alldata = subset(alldata, diabeteshosp_prior_aki_denom >0)

### PM2.5 ###
model<-gnm(diabeteshosp_prior_aki~pm25.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(diabeteshosp_prior_aki_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata[alldata$diabeteshosp_prior_aki_denom>0, ],family=poisson(link="log"), na.action=na.exclude)

coef_aki_pm_diaprior<-model$coefficient[1]
write.csv(coef_aki_pm_diaprior,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/point_aki_pm25_diaprior.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample & diabeteshosp_prior_aki_denom >0)
    
    model<-gnm(diabeteshosp_prior_aki~pm25.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(diabeteshosp_prior_aki_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"), na.action=na.exclude)
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_pm_diaprior<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_pm_diaprior,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/se_aki_pm25_diaprior.csv")

### Summer Ozone ###
model<-gnm(diabeteshosp_prior_aki~ozone_summer.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(diabeteshosp_prior_aki_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_o3_diaprior<-model$coefficient[1]
write.csv(coef_aki_o3_diaprior,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/point_aki_o3_diaprior.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample & diabeteshosp_prior_aki_denom >0)
    
    model<-gnm(diabeteshosp_prior_aki~ozone_summer.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(diabeteshosp_prior_aki_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"), na.action=na.exclude)
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_o3_diaprior<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_o3_diaprior,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/se_aki_o3_diaprior.csv")

### NO2 ###
model<-gnm(diabeteshosp_prior_aki~no2.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(diabeteshosp_prior_aki_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_no2_diaprior<-model$coefficient[1]
write.csv(coef_aki_no2_diaprior,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/point_aki_no2_diaprior.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample & diabeteshosp_prior_aki_denom>0)
    
    model<-gnm(diabeteshosp_prior_aki~no2.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(diabeteshosp_prior_aki_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"), na.action=na.exclude)
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_no2_diaprior<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_no2_diaprior,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/se_aki_no2_diaprior.csv")


### 3. UTI Primary / AKI Secondary ###
alldata<-readRDS("/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/data/alldata_first_hos_aki_0016(2).rds")
alldata$pct_hispanic<-1-c(alldata$pct_asian+alldata$pct_blk+alldata$pct_native+alldata$pct_white)
alldata = subset(alldata, select=c('uti_primary_aki_secondary_first_hosp', 
                                   'uti_primary_aki_secondary_first_hosp_denom', 
                                   'pm25.current_year', 'ozone_summer.current_year', 'no2.current_year',
                                   'year', 'region', 'poverty', 'popdensity', 'medianhousevalue', 
                                   'pct_blk', 'pct_hispanic', 'medhouseholdincome', 'pct_owner_occ', 
                                   'education', 'smoke_rate', 'mean_bmi', 'race', 'entry_age_group', 'follow_up', 
                                   'sex', 'dual', 'zip'))
alldata = subset(alldata, uti_primary_aki_secondary_first_hosp_denom >0)

### PM2.5 ###
model<-gnm(uti_primary_aki_secondary_first_hosp~pm25.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(uti_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_pm_utiprimary<-model$coefficient[1]
write.csv(coef_aki_pm_utiprimary,"/nfs/home/W/whl313/shared_space/ci3_whl313/result/20220625/point_aki_pm25_utiprimary.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample)
    
    model<-gnm(uti_primary_aki_secondary_first_hosp~pm25.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(uti_primary_aki_secondary_first_hosp_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"), na.action=na.exclude)
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_pm_utiprimary<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_pm_utiprimary,"/nfs/home/W/whl313/shared_space/ci3_whl313/result/20220625/se_aki_pm25_utiprimary.csv")

### Summer Ozone ###
model<-gnm(uti_primary_aki_secondary_first_hosp~ozone_summer.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(uti_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata[alldata$uti_primary_aki_secondary_first_hosp_denom>0,],family=poisson(link="log"), na.action=na.exclude)

coef_aki_o3_utiprimary<-model$coefficient[1]
write.csv(coef_aki_o3_utiprimary,"/nfs/home/W/whl313/shared_space/ci3_whl313/result/20220625/point_aki_o3_utiprimary.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample)
    
    model<-gnm(uti_primary_aki_secondary_first_hosp~ozone_summer.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(uti_primary_aki_secondary_first_hosp_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"))
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_o3_utiprimary<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_o3_utiprimary,"/nfs/home/W/whl313/shared_space/ci3_whl313/result/20220625/se_aki_o3_utiprimary.csv")

### NO2 ###
model<-gnm(uti_primary_aki_secondary_first_hosp~no2.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(uti_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_no2_utiprimary<-model$coefficient[1]
write.csv(coef_aki_no2_utiprimary,"/nfs/home/W/whl313/shared_space/ci3_whl313/result/20220625/point_aki_no2_utiprimary.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample)
    
    model<-gnm(uti_primary_aki_secondary_first_hosp~no2.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(uti_primary_aki_secondary_first_hosp_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"))
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_no2_utiprimary<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_no2_utiprimary,"/nfs/home/W/whl313/shared_space/ci3_whl313/result/20220625/se_aki_no2_utiprimary.csv")


### 4. CERD Primary / AKI Secondary ###

alldata<-readRDS("/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/data/alldata_first_hos_aki_0016(2).rds")
alldata$pct_hispanic<-1-c(alldata$pct_asian+alldata$pct_blk+alldata$pct_native+alldata$pct_white)
alldata = subset(alldata, select=c('cerd_primary_aki_secondary_first_hosp', 
                                   'cerd_primary_aki_secondary_first_hosp_denom', 
                                   'pm25.current_year', 'ozone_summer.current_year', 'no2.current_year',
                                   'year', 'region', 'poverty', 'popdensity', 'medianhousevalue', 
                                   'pct_blk', 'pct_hispanic', 'medhouseholdincome', 'pct_owner_occ', 
                                   'education', 'smoke_rate', 'mean_bmi', 'race', 'entry_age_group', 'follow_up', 
                                   'sex', 'dual', 'zip'))
alldata = subset(alldata, cerd_primary_aki_secondary_first_hosp_denom >0)
### PM2.5 ###
model<-gnm(cerd_primary_aki_secondary_first_hosp~pm25.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(cerd_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_pm_cerdprimary<-model$coefficient[1]
write.csv(coef_aki_pm_cerdprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/point_aki_pm25_cerdprimary.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample & cerd_primary_aki_secondary_first_hosp_denom>0)
    
    model<-gnm(cerd_primary_aki_secondary_first_hosp~pm25.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(cerd_primary_aki_secondary_first_hosp_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"), na.action=na.exclude)
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_pm_cerdprimary<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_pm_cerdprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/se_aki_pm25_cerdprimary.csv")

### Summer Ozone ###
model<-gnm(cerd_primary_aki_secondary_first_hosp~ozone_summer.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(cerd_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_o3_cerdprimary<-model$coefficient[1]
write.csv(coef_aki_o3_cerdprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/point_aki_o3_cerdprimary.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample & cerd_primary_aki_secondary_first_hosp_denom>0)
    
    model<-gnm(cerd_primary_aki_secondary_first_hosp~ozone_summer.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(cerd_primary_aki_secondary_first_hosp_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"))
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_o3_cerdprimary<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_o3_cerdprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/se_aki_o3_cerdprimary.csv")

### NO2 ###
model<-gnm(cerd_primary_aki_secondary_first_hosp~no2.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(cerd_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_no2_cerdprimary<-model$coefficient[1]
write.csv(coef_aki_no2_cerdprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/point_aki_no2_cerdprimary.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample & cerd_primary_aki_secondary_first_hosp_denom>0)
    
    model<-gnm(cerd_primary_aki_secondary_first_hosp~no2.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(cerd_primary_aki_secondary_first_hosp_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"))
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_no2_cerdprimary<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_no2_cerdprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/se_aki_no2_cerdprimary.csv")


### 5. AMI Primary / AKI Secondary ###
alldata<-readRDS("/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/data/alldata_first_hos_aki_0016(2).rds")
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
write.csv(coef_aki_pm_amiprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/point_aki_pm25_amiprimary.csv")
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
write.csv(aki_se_pm_amiprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/se_aki_pm25_amiprimary.csv")

### Summer Ozone ###
model<-gnm(ami_primary_aki_secondary_first_hosp~ozone_summer.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(ami_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_o3_amiprimary<-model$coefficient[1]
write.csv(coef_aki_o3_amiprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/point_aki_o3_amiprimary.csv")
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
write.csv(aki_se_o3_amiprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/se_aki_o3_amiprimary.csv")

### NO2 ###
model<-gnm(ami_primary_aki_secondary_first_hosp~no2.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(ami_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_no2_amiprimary<-model$coefficient[1]
write.csv(coef_aki_no2_amiprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/point_aki_no2_amiprimary.csv")
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
write.csv(aki_se_no2_amiprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/se_aki_no2_amiprimary.csv")


### 6. HF Primary / AKI Secondary ###
alldata<-readRDS("/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/data/alldata_first_hos_aki_0016(2).rds")
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
write.csv(coef_aki_pm_hfprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/point_aki_pm25_hfprimary.csv")
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
write.csv(aki_se_pm_hfprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/se_aki_pm25_hfprimary.csv")

### Summer Ozone ###
model<-gnm(hf_primary_aki_secondary_first_hosp~ozone_summer.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(hf_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_o3_hfprimary<-model$coefficient[1]
write.csv(coef_aki_o3_hfprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/point_aki_o3_hfprimary.csv")
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
write.csv(aki_se_o3_hfprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/se_aki_o3_hfprimary.csv")

### NO2 ###
model<-gnm(hf_primary_aki_secondary_first_hosp~no2.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(hf_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_no2_hfprimary<-model$coefficient[1]
write.csv(coef_aki_no2_hfprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/point_aki_no2_hfprimary.csv")
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
write.csv(aki_se_no2_hfprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/se_aki_no2_hfprimary.csv")


### 7. Pneumonia Primary / AKI Secondary ###

alldata<-readRDS("/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/data/alldata_first_hos_aki_0016(2).rds")
alldata$pct_hispanic<-1-c(alldata$pct_asian+alldata$pct_blk+alldata$pct_native+alldata$pct_white)
alldata = subset(alldata, select=c('pneumonia_primary_aki_secondary_first_hosp', 
                                   'pneumonia_primary_aki_secondary_first_hosp_denom', 
                                   'pm25.current_year', 'ozone_summer.current_year', 'no2.current_year',
                                   'year', 'region', 'poverty', 'popdensity', 'medianhousevalue', 
                                   'pct_blk', 'pct_hispanic', 'medhouseholdincome', 'pct_owner_occ', 
                                   'education', 'smoke_rate', 'mean_bmi', 'race', 'entry_age_group', 'follow_up', 
                                   'sex', 'dual', 'zip'))
alldata = subset(alldata, pneumonia_primary_aki_secondary_first_hosp_denom >0)
### PM2.5 ###
model<-gnm(pneumonia_primary_aki_secondary_first_hosp~pm25.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(pneumonia_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_pm_pneuprimary<-model$coefficient[1]
write.csv(coef_aki_pm_pneuprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/point_aki_pm25_pneuprimary.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample &pneumonia_primary_aki_secondary_first_hosp_denom>0)
    
    model<-gnm(pneumonia_primary_aki_secondary_first_hosp~pm25.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(pneumonia_primary_aki_secondary_first_hosp_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"), na.action=na.exclude)
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_pm_pneuprimary<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_pm_pneuprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/se_aki_pm25_pneuprimary.csv")
aki_se_pm_pneuprimary

### Summer Ozone ###
model<-gnm(pneumonia_primary_aki_secondary_first_hosp~ozone_summer.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(pneumonia_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_o3_pneuprimary<-model$coefficient[1]
write.csv(coef_aki_o3_pneuprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/point_aki_o3_pneuprimary.csv")
rm(model);gc()
coef_aki_o3_pneuprimary

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample & pneumonia_primary_aki_secondary_first_hosp_denom>0)
    
    model<-gnm(pneumonia_primary_aki_secondary_first_hosp~ozone_summer.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(pneumonia_primary_aki_secondary_first_hosp_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"))
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_o3_pneuprimary<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_o3_pneuprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/se_aki_o3_pneuprimary.csv")
aki_se_o3_pneuprimary


### NO2 ###
model<-gnm(pneumonia_primary_aki_secondary_first_hosp~no2.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(pneumonia_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_no2_pneuprimary<-model$coefficient[1]
write.csv(coef_aki_no2_pneuprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/point_aki_no2_pneuprimary.csv")
rm(model);gc()
coef_aki_no2_pneuprimary


### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample &
                         pneumonia_primary_aki_secondary_first_hosp_denom >0 )
    
    model<-gnm(pneumonia_primary_aki_secondary_first_hosp~no2.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(pneumonia_primary_aki_secondary_first_hosp_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"))
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_no2_pneuprimary<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_no2_pneuprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/se_aki_no2_pneuprimary.csv")


### 8. IHD Primary / AKI Secondary ###
alldata<-readRDS("/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/data/alldata_first_hos_aki_0016(2).rds")
alldata$pct_hispanic<-1-c(alldata$pct_asian+alldata$pct_blk+alldata$pct_native+alldata$pct_white)
alldata = subset(alldata, select=c('ihd_primary_aki_secondary_first_hosp', 
                                   'ihd_primary_aki_secondary_first_hosp_denom', 
                                   'pm25.current_year', 'ozone_summer.current_year', 'no2.current_year',
                                   'year', 'region', 'poverty', 'popdensity', 'medianhousevalue', 
                                   'pct_blk', 'pct_hispanic', 'medhouseholdincome', 'pct_owner_occ', 
                                   'education', 'smoke_rate', 'mean_bmi', 'race', 'entry_age_group', 'follow_up', 
                                   'sex', 'dual', 'zip'))
alldata = subset(alldata, ihd_primary_aki_secondary_first_hosp_denom >0)
### PM2.5 ###
model<-gnm(ihd_primary_aki_secondary_first_hosp~pm25.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(ihd_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_pm_ihdprimary<-model$coefficient[1]
write.csv(coef_aki_pm_ihdprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/point_aki_pm25_ihdprimary.csv")
rm(model);gc()
coef_aki_pm_ihdprimary

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample & ihd_primary_aki_secondary_first_hosp_denom>0)
    
    model<-gnm(ihd_primary_aki_secondary_first_hosp~pm25.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(ihd_primary_aki_secondary_first_hosp_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"), na.action=na.exclude)
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_pm_ihdprimary<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_pm_ihdprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/se_aki_pm25_ihdprimary.csv")
aki_se_pm_ihdprimary

### Summer Ozone ###
model<-gnm(ihd_primary_aki_secondary_first_hosp~ozone_summer.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(ihd_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_o3_ihdprimary<-model$coefficient[1]
write.csv(coef_aki_o3_ihdprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/point_aki_o3_ihdprimary.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample)
    
    model<-gnm(ihd_primary_aki_secondary_first_hosp~ozone_summer.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(ihd_primary_aki_secondary_first_hosp_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"), na.action=na.exclude)
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_o3_ihdprimary<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_o3_ihdprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/se_aki_o3_ihdprimary.csv")

### NO2 ###
model<-gnm(ihd_primary_aki_secondary_first_hosp~no2.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(ihd_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_no2_ihdprimary<-model$coefficient[1]
write.csv(coef_aki_no2_ihdprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/point_aki_no2_ihdprimary.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample & 
                         ihd_primary_aki_secondary_first_hosp_denom >0 )
    
    model<-gnm(ihd_primary_aki_secondary_first_hosp~no2.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(ihd_primary_aki_secondary_first_hosp_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"), na.action=na.exclude)
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_no2_ihdprimary<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_no2_ihdprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/se_aki_no2_ihdprimary.csv")


### 9. CSD Primary / AKI Secondary ###
alldata<-readRDS("/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/data/alldata_first_hos_aki_0016.rds")
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
write.csv(coef_aki_pm_csdprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/point_aki_pm25_csdprimary.csv")
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
write.csv(aki_se_pm_csdprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/se_aki_pm25_csdprimary.csv")

### Summer Ozone ###
model<-gnm(csd_primary_aki_secondary_first_hosp~ozone_summer.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(csd_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_o3_csdprimary<-model$coefficient[1]
write.csv(coef_aki_o3_csdprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/point_aki_o3_csdprimary.csv")
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
write.csv(aki_se_o3_csdprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/se_aki_o3_csdprimary.csv")

### NO2 ###
model<-gnm(csd_primary_aki_secondary_first_hosp~no2.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(csd_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_no2_csdprimary<-model$coefficient[1]
write.csv(coef_aki_no2_csdprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/point_aki_no2_csdprimary.csv")
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
write.csv(aki_se_no2_csdprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/se_aki_no2_csdprimary.csv")


### 10. Diabetes Primary / AKI Secondary ###
alldata<-readRDS("/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/data/alldata_first_hos_aki_0016.rds")
alldata$pct_hispanic<-1-c(alldata$pct_asian+alldata$pct_blk+alldata$pct_native+alldata$pct_white)
alldata = subset(alldata, select=c('diabetes_primary_aki_secondary_first_hosp', 
                                   'diabetes_primary_aki_secondary_first_hosp_denom', 
                                   'pm25.current_year', 'ozone_summer.current_year', 'no2.current_year',
                                   'year', 'region', 'poverty', 'popdensity', 'medianhousevalue', 
                                   'pct_blk', 'pct_hispanic', 'medhouseholdincome', 'pct_owner_occ', 
                                   'education', 'smoke_rate', 'mean_bmi', 'race', 'entry_age_group', 'follow_up', 
                                   'sex', 'dual', 'zip'))
alldata = subset(alldata, diabetes_primary_aki_secondary_first_hosp_denom >0)
### PM2.5 ###
model<-gnm(diabetes_primary_aki_secondary_first_hosp~pm25.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(diabetes_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log") ,na.action=na.exclude)

coef_aki_pm_diaprimary<-model$coefficient[1]
write.csv(coef_aki_pm_diaprimary,"/nfs/home/S/seh415/shared_space/ci3_analysis/whanhee_revisions/out/20220625/point_aki_pm25_diaprimary.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample)
    
    model<-gnm(diabetes_primary_aki_secondary_first_hosp~pm25.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(diabetes_primary_aki_secondary_first_hosp_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"))
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_pm_diaprimary<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_pm_diaprimary,"/nfs/home/W/whl313/shared_space/ci3_whl313/result/20220625/se_aki_pm25_diaprimary.csv")

### Summer Ozone ###
model<-gnm(diabetes_primary_aki_secondary_first_hosp~ozone_summer.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(diabetes_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"), na.action=na.exclude)

coef_aki_o3_diaprimary<-model$coefficient[1]
write.csv(coef_aki_o3_diaprimary,"/nfs/home/W/whl313/shared_space/ci3_whl313/result/20220625/point_aki_o3_diaprimary.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample)
    
    model<-gnm(diabetes_primary_aki_secondary_first_hosp~ozone_summer.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(diabetes_primary_aki_secondary_first_hosp_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"))
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_o3_diaprimary<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_o3_diaprimary,"/nfs/home/W/whl313/shared_space/ci3_whl313/result/20220625/se_aki_o3_diaprimary.csv")

### NO2 ###
model<-gnm(diabetes_primary_aki_secondary_first_hosp~no2.current_year+factor(year)+factor(region)+
             poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
             medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
             as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
             offset(log(diabetes_primary_aki_secondary_first_hosp_denom)),
             eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
             data=alldata,family=poisson(link="log"))

coef_aki_no2_diaprimary<-model$coefficient[1]
write.csv(coef_aki_no2_diaprimary,"/nfs/home/W/whl313/shared_space/ci3_whl313/result/20220625/point_aki_no2_diaprimary.csv")
rm(model);gc()

### Bootstrapping ###
num_uniq_zip<-length(unique(alldata$zip))
coefs_boots<-NULL

for(boots_id in 1:500){
  tryCatch({
    set.seed(boots_id)
    zip_sample<-sample(1:num_uniq_zip,floor(2*sqrt(num_uniq_zip)),replace=T)
    
    data_boots<-subset(alldata,alldata$zip %in% zip_sample)
    
    model<-gnm(diabetes_primary_aki_secondary_first_hosp~no2.current_year+factor(year)+factor(region)+
                 poverty+popdensity+medianhousevalue+pct_blk+pct_hispanic+
                 medhouseholdincome+pct_owner_occ+education+smoke_rate+mean_bmi+
                 as.factor(race)+as.factor(entry_age_group)+as.factor(follow_up)+as.factor(sex)+as.factor(dual)+
                 offset(log(diabetes_primary_aki_secondary_first_hosp_denom)),
               eliminate=(as.factor(race):as.factor(entry_age_group):as.factor(follow_up):as.factor(sex):as.factor(dual)),
               data=data_boots,family=poisson(link="log"))
    
    coefs_boots<-c(coefs_boots,model$coefficients[1])
    rm(model);gc()
  }, error=function(e){})
}
rm(data_boots);gc()

#SE
aki_se_no2_diaprimary<-sd(coefs_boots)*sqrt(floor(2*sqrt(num_uniq_zip)))/sqrt(num_uniq_zip)
write.csv(aki_se_no2_diaprimary,"/nfs/home/W/whl313/shared_space/ci3_whl313/result/20220625/se_aki_no2_diaprimary.csv")

