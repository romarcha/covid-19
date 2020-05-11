rm(list = ls())

# Installing required packages
packages = c("plyr", "dplyr")
install.packages(packages)
lapply(packages, require, character.only = T)

# Path to working directory
wkdir = "~/Code/covid-19"

# Model name
model = c("UT_US", "UT_states")

for(i in 1:length(model)){
  # Set working directory
  setwd(paste0(wkdir, "/", model[i]))
  
  # Ground truth source
  gt_source = "JHU&NYT"
  
  # Load all csv files in the model folder and combine all data
  csv_file      = list.files(pattern=paste0("^", model[i], "(.*)csv$"))
  prediction    = lapply(1:length(csv_file), function(i) read.csv(csv_file[i]))
  num_entry     = unlist(lapply(prediction, nrow))
  forecast_date = rep(do.call("c", (lapply(1:length(csv_file), function(i) 
                  max(as.Date(prediction[[i]]$date[!is.na(prediction[[i]]$daily_deaths_actual)]))))), num_entry)
  if (model[i] == "UT_US"){
    prediction = cbind(state="United States", forecast_date=forecast_date, do.call(rbind.fill, prediction))
  }else{
    prediction = cbind(forecast_date=forecast_date, do.call(rbind.fill, prediction))
  }
  
  prediction$date = as.Date(prediction$date)
  prediction      = prediction[!is.na(prediction$daily_deaths_est),]
  
  # Ground truth is based on NYT until 2020-05-05
  var             = prediction$forecast_date==as.Date("2020-05-05") & !is.na(prediction$daily_deaths_actual)
  ground_truth_p1 = data.frame(state=prediction$state[var], date=prediction$date[var], actual_death=prediction$daily_deaths_actual[var])
  prediction_p1   = prediction[prediction$forecast_date < as.Date("2020-05-05") & prediction$date <= as.Date("2020-05-05") & is.na(prediction$daily_deaths_actual),]
  prediction_p1   = join_all(list(prediction_p1[,colnames(prediction_p1)!="daily_deaths_actual"], ground_truth_p1), by=c("date", "state"))
  
  # Ground truth is based on JHU from 2020-05-06
  var             = prediction$forecast_date==max(prediction$forecast_date) & !is.na(prediction$daily_deaths_actual)
  ground_truth_p2 = data.frame(state=prediction$state[var], date=prediction$date[var], actual_death=prediction$daily_deaths_actual[var])
  prediction_p2   = prediction[prediction$forecast_date > as.Date("2020-05-05") & is.na(prediction$daily_deaths_actual),]
  prediction_p2   = join_all(list(prediction_p2[,colnames(prediction_p2)!="daily_deaths_actual"], ground_truth_p2), by=c("date", "state"))
  
  # Merging prediction from both periods
  all_merge = rbind.fill(prediction_p1, prediction_p2)
  
  location_long  = all_merge$state
  if(model[i] == "UT_US"){
    location_short = "USA"
  }else{
    location_short = mapvalues(all_merge$state, from=state.name, to=state.abb)
  }
  
  # Calculating various measure
  error  = all_merge$actual_death - all_merge$daily_deaths_est
  pe     = error/all_merge$actual_death * 100
  adj_pe = error/(all_merge$actual_death + all_merge$daily_deaths_est) * 100
  
  pe[all_merge$daily_deaths_est==0 & all_merge$actual_death==0]     = 0
  adj_pe[all_merge$daily_deaths_est==0 & all_merge$actual_death==0] = 0
  pe[all_merge$daily_deaths_est!=0 & all_merge$actual_death==0]     = Inf
  
  ape              = abs(pe)
  adj_ape          = abs(adj_pe)
  logistic_ape     = 1 / (1 + exp(-ape/100))
  logistic_adj_ape = 1 / (1 + exp(-adj_ape/100))
  
  within_95_pi   = NA
  outside_95p_by = NA
  
  df = data.frame(target_date      = all_merge$date, 
                  forecast_date    = all_merge$forecast_date, 
                  lookahead        = difftime(all_merge$date, all_merge$forecast_date, units="days"),
                  model_name       = model[i],
                  location_long    = location_long,
                  location_short   = location_short,
                  prediction_type  = "90PI",
                  expected_value   = all_merge$daily_deaths_est,
                  perc_0.010       = NA,
                  perc_0.025       = NA,
                  perc_0.050       = all_merge$daily_deaths_90CI_lower,
                  perc_0.100       = NA,
                  perc_0.150       = NA,
                  perc_0.200       = NA,
                  perc_0.250       = NA,
                  perc_0.300       = NA,
                  perc_0.350       = NA,
                  perc_0.400       = NA,
                  perc_0.450       = NA,
                  perc_0.500       = NA,
                  perc_0.550       = NA,
                  perc_0.600       = NA,
                  perc_0.650       = NA,
                  perc_0.700       = NA,
                  perc_0.750       = NA,
                  perc_0.800       = NA,
                  perc_0.850       = NA,
                  perc_0.900       = NA,
                  perc_0.950       = all_merge$daily_deaths_90CI_upper,
                  perc_0.975       = NA,
                  perc_0.990       = NA,
                  gt_source        = gt_source,
                  gt_jhu           = all_merge$actual_death,
                  gt_nyt           = all_merge$actual_death,
                  gt_ecdc          = NA,
                  error            = error,
                  pe               = pe,
                  adj_pe           = adj_pe,
                  ape              = ape,
                  adj_ape          = adj_ape,
                  logistic_ape     = logistic_ape,
                  logistic_adj_ape = logistic_adj_ape,
                  within_95_pi     = within_95_pi,
                  outside_95p_by   = outside_95p_by
  )
  
  df$gt_jhu[df$forecast_date < as.Date("2020-05-05")] = NA
  df$gt_nyt[df$forecast_date > as.Date("2020-05-05")] = NA
  df = df[df$lookahead!=0,]
  
  setwd(wkdir)
  
  # Save data frame in summary folder
  files_in_dir = list.files()
  if("summary" %in% files_in_dir == F){
    dir.create("summary")
  }
  setwd(paste0(wkdir, "/summary/"))
  
  write.csv(df, paste0(model[i], "-summary.csv"), row.names = F)
  setwd(wkdir)
}
rm(list = ls())