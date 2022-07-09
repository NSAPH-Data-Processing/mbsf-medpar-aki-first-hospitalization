library(devtools)
#library(fst)
#library(NSAPHutils)
library(parallel)
library(data.table)
library(plyr)

### Data Step ###
alldata<-read.csv("../data/final_2.csv")

#State code
zcta_code<-fread("Zip_to_ZCTA_crosswalk_2015_JSI.csv")
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
tempdata<-readRDS("NARR0016_zipcode.rds")
tempdata$year<-as.numeric(substr(tempdata$date,1,4))

annual_temp<-aggregate(x=tempdata$air_temp_2m,by=list(tempdata$zipc,tempdata$year),FUN=mean,na.rm=T)
colnames(annual_temp)<-c("zip","year","temp_annual_k")
annual_temp$temp_annual<-annual_temp$temp_annual_k-273
annual_temp$zip<-as.numeric(annual_temp$zip)

alldata<-merge(alldata,annual_temp,by=c("zip","year"),all.x=TRUE)
saveRDS(alldata,"alldata_first_hos_aki2.rds")
rm(alldata)

