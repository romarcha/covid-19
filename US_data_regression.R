#################################################prepare the data


us=read.csv('../raw-data/us_result.csv')
# gt=read.csv('../raw-data/gt.csv')
library(dplyr)
library(tidyr)
library(Hmisc)
models= c("Geneva","YYG") # YYG and IHME predict USA and also states, Geneva only predicts USA
us=filter(us,model_name %in% models,location_long =="United States")

ahead=7 # decide how many days are included in the regression


us_part1=filter(us,model_name %in% models[1])

us_part1=group_by(us_part1,target_end_date,forecast_date,model_name,gt_source)
us_part1=summarise(us_part1,expected_value=sum(expected_value),gt=sum(gt),lookahead=mean(lookahead))

us_part2=filter(us,model_name %in% models[2]) # YYG predict USA and also states
us_part2=group_by(us_part2,target_end_date,forecast_date,model_name,gt_source)
us_part2=summarise(us_part2,expected_value=max(expected_value),gt=max(gt),lookahead=mean(lookahead))

us_group=bind_rows(us_part1,us_part2)

us_wide=pivot_wider(us_group,names_from = c("model_name"), values_from = expected_value) %>% filter(.,as.Date(forecast_date)>as.Date("2020-04-14")) %>%filter(.,lookahead<=ahead) %>%filter(.,gt>=0)  %>%filter(.,gt_source %in% c("JHU","ECDC"))  

for(i in 1:nrow(us_wide)){
  temp=filter(us_wide,forecast_date==us_wide$forecast_date[i],target_end_date==us_wide$target_end_date[i])
  us_wide[i,models[1]]=mean(as.matrix(temp[,models[1]]),na.rm = T)
  us_wide[i,models[2]]=mean(as.matrix(temp[,models[2]]),na.rm = T)
  
}

us_wide=ungroup(filter(us_wide,gt_source=="JHU")) %>% dplyr::select(.,-forecast_date,-gt_source)

us_wide=pivot_wider(us_wide,names_from = lookahead,values_from = c("Geneva","YYG"))
us_wide=drop_na(us_wide) %>% mutate(.,week=as.numeric(weekdays(as.Date(target_end_date)) %in% c("Saturday","Sunday","Monday"))) 
us_wide$target_end_date=as.Date(us_wide$target_end_date)
us_wide=us_wide[order(us_wide$target_end_date),]
## take the data into log-scale
us_wide_log=(us_wide)
us_wide_log[,c(2:16)]=log(us_wide_log[,c(2:16)])
####----
#   -----------------------------------------------------------Data is ready

####----
#------------------------------------------------------------------EDA plots
source('US_regression_EDA.R')

save.image("../Results/US_data_regression.RData")