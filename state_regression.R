#################################################prepare the data
us=read.csv('../raw-data/us_result.csv')

library(dplyr)
library(tidyr)
models= c("YYG") # YYG and IHME predict USA and also states, Geneva only predicts USA
ahead=7 # decide how many days are included in the regression
us=filter(us,model_name %in% models,location_short != "USA",lookahead<=ahead)

us=group_by(us,target_end_date,forecast_date,model_name,gt_source,location_short)
us=summarise(us,expected_value=(expected_value),gt=(gt),lookahead=(lookahead))




us_wide=pivot_wider(us,names_from = c("model_name"), values_from = expected_value) %>% filter(.,as.Date(forecast_date)>as.Date("2020-04-14")) %>%filter(.,gt>=0)  %>%filter(.,gt_source %in% c("JHU","ECDC"))  

#for(i in 1:nrow(us_wide)){
#  temp=filter(us_wide,forecast_date==us_wide$forecast_date[i],target_end_date==us_wide$target_end_date[i])
#  us_wide[i,models[1]]=mean(as.matrix(temp[,models[1]]),na.rm = T)
#  us_wide[i,models[2]]=mean(as.matrix(temp[,models[2]]),na.rm = T)
  
#}

us_wide=ungroup(filter(us_wide,gt_source=="JHU")) %>% dplyr::select(.,-forecast_date,-gt_source)

us_wide=pivot_wider(us_wide,names_from = lookahead,values_from = "YYG",names_prefix = "YYG_")
us_wide=drop_na(us_wide) %>% mutate(.,week=as.numeric(weekdays(as.Date(target_end_date)) %in% c("Saturday","Sunday","Monday"))) 
us_wide$target_end_date=as.Date(us_wide$target_end_date)
us_wide=us_wide[order(us_wide$target_end_date),]
## take the data into log-scale
us_wide_log=(us_wide)
us_wide_log[,c(3:10)]=log(us_wide_log[,c(3:10)]+1) # deal with value of zero's


train.num=36 # split training and prediction set

## regression state-wise
states=as.character(unique(us_wide_log$location_short))
coef.mat=matrix(NA,nrow = length(states),ncol=ncol(us_wide_log)-2)
colnames(coef.mat)=c("Intercept",names(us_wide_log)[4:11])
for(i in 1:length(states)){
  datatemp=filter(us_wide_log,location_short==states[i])
  model=lm(gt~. ,data=datatemp[1:train.num,-c(1,2)])
  coef.mat[i,]=model$coefficients
}

coef.mat=as_tibble(coef.mat) %>% mutate(.,state=states)

boxplot(coef.mat[,1:9])
coef.mat

library(usmap)
library(ggplot2)
library(maps) 

for(i in 1:9){
  p=plot_usmap(data = coef.mat, values = colnames(coef.mat)[i], color = "red") + 
    scale_fill_continuous(low='white', high= 'red',name = colnames(coef.mat)[i], label = scales::comma) + 
    theme(legend.position = "right") 
  print(p)
}



# https://remiller1450.github.io/s230s19/Intro_maps.html

