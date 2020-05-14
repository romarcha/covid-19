rm(list = ls())

# Installing required packages
packages = c("plyr", "dplyr", "downloader", "usmap", "countrycode")
install.packages(packages)
lapply(packages, require, character.only = T)

# Path to working directory and set work directory
wkdir = "~/Code/covid-19"
setwd(wkdir)

# Model name and ground truth used
model = c("YYG_states", "NotreDame")
model_name = c("YYG", "NotreDame")
gt_source=c("JHU", "NYT")

code_table = data.frame(location_name=c(state.name, "District of Columbia", "American Samoa", "Guam", "Northern Mariana Islands", "Puerto Rico", "US Virgin Islands", "United States"),
                        fips=c(fips(c(state.name, "District of Columbia")), "60", "66", "69", "72", "78", "US"),
                        abb=c(state.abb, "DC", "ASM", "GUM", "MNP", "PRI", "VIR", "USA"))

# JHU Global Data
print("Downloading ground truth global data from JHU")
download("https://github.com/CSSEGISandData/COVID-19/raw/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv",
         "jhu_truth_global.csv", quiet=T)
jhu_truth_global = read.csv("jhu_truth_global.csv")
unlink("jhu_truth_global.csv", recursive=T)
jhu_truth_global = jhu_truth_global[jhu_truth_global$Country.Region %in% c("United States of America", "United States", "US", "USA"),]
inc_death_us     = apply(jhu_truth_global[,5:ncol(jhu_truth_global)], 1, diff)
if (all(inc_death_us>=0)==F){
  warning("Negative incident deaths reported in ground truth data!")
}
jhu_truth_us = data.frame(location_name=rep("United States", nrow(inc_death_us)),
                          target_end_date=rep(seq(as.Date("2020-01-23"), as.Date("2020-01-23") + nrow(inc_death_us) - 1, by="days"), ncol(inc_death_us)),
                          incident.death=as.vector(inc_death_us))

# JHU US States Data
print("Downloading ground truth US states data from JHU")
download("https://github.com/CSSEGISandData/COVID-19/raw/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv",
         "jhu_truth_states.csv", quiet=T)
jhu_truth_states = read.csv("jhu_truth_states.csv")
unlink("jhu_truth_states.csv", recursive=T)
jhu_truth_states = jhu_truth_states[jhu_truth_states$Lat!=0 | jhu_truth_states$Long_!=0,]
levels(jhu_truth_states$Province_State)[levels(jhu_truth_states$Province_State)=="Virgin Islands"] = "US Virgin Islands"
jhu_truth_states = aggregate(.~Province_State, jhu_truth_states, sum)
cum_death_states = jhu_truth_states[,13:ncol(jhu_truth_states)]
inc_death_states = apply(cum_death_states, 1, diff)
if (all(inc_death_states>=0)==F){
  warning("Negative incident deaths reported in ground truth data!")
}
jhu_truth_states = data.frame(location_name=rep(jhu_truth_states$Province_State, each=nrow(inc_death_states)),
                              target_end_date=rep(seq(as.Date("2020-01-23"), as.Date("2020-01-23") + nrow(inc_death_states) - 1, by="days"), ncol(inc_death_states)),
                              incident.death=as.vector(inc_death_states))
jhu_truth_states = rbind.fill(jhu_truth_states, jhu_truth_us)

# NYT Data
print("Downloading ground truth US states data from NYT")
download("https://github.com/nytimes/covid-19-data/raw/master/us-states.csv", "nyt_truth.csv", quiet=T)
nyt_truth      = read.csv("nyt_truth.csv")
unlink("nyt_truth.csv", recursive=T)
nyt_truth$date = as.Date(nyt_truth$date)
nyt_truth      = reshape(nyt_truth[,colnames(nyt_truth) %in% c("date", "state", "deaths")], idvar="state", timevar="date", direction="wide")
nyt_truth[is.na(nyt_truth)] = 0
nyt_inc_death  = apply(nyt_truth[,2:ncol(nyt_truth)], 1, diff)
nyt_truth_states = data.frame(location_name=rep(nyt_truth$state, each=nrow(nyt_inc_death)),
                              target_end_date=rep(seq(as.Date("2020-01-22"), as.Date("2020-01-22") + nrow(nyt_inc_death) - 1, by="days"), ncol(nyt_inc_death)),
                              incident.death=as.vector(nyt_inc_death))
if (all(nyt_inc_death>=0)==F){
  warning("Negative incident deaths reported in ground truth data!")
}

for(i in 1:length(model)){
  # Set working directory
  setwd(paste0(wkdir, "/", model[i]))
  
  # Load all csv files in the model folder and combine all data
  csv_file                   = list.files(pattern=paste0("^", model[i], "(.*)csv$"))
  prediction                 = do.call(rbind.fill, lapply(1:length(csv_file), function(i) read.csv(csv_file[i])))
  prediction$forecast_date   = as.Date(prediction$forecast_date)
  prediction$target_end_date = as.Date(prediction$target_end_date)
  
  # Remove cumulative death, extra columns and impute NA as pt in quantile
  prediction = prediction[grepl("day ahead inc", prediction$target),]
  prediction = prediction[,colnames(prediction) %in% c("forecast_date", "target_end_date", "location_name", "quantile", "value")]
  prediction$quantile[is.na(prediction$quantile)] = "pt"
  levels(prediction$location_name)[levels(prediction$location_name)=="Virgin Islands"] = "US Virgin Islands"
  levels(prediction$location_name)[levels(prediction$location_name)=="US"] = "United States"
  
  # Convert to wide data
  prediction = reshape(prediction, idvar=c("forecast_date", "target_end_date", "location_name"), timevar = "quantile", direction = "wide")
  
  # Merging prediction with ground truth
  if(gt_source[i]=="JHU"){
    all_merge = join_all(list(prediction, jhu_truth_states), by=c("target_end_date", "location_name"))
  }else if(gt_source[i]=="NYT"){
    all_merge = join_all(list(prediction, nyt_truth_states), by=c("target_end_date", "location_name"))
  }
  
  # Location long and location short
  location_long  = all_merge$location_name
  location_short = mapvalues(all_merge$location_name, from=as.character(code_table$location_name), to=as.character(code_table$abb))
  
  # Calculating various measure
  error  = all_merge$incident.death - all_merge$value.pt
  pe     = error/all_merge$incident.death * 100
  adj_pe = error/(all_merge$incident.death + all_merge$value.pt) * 100
  
  pe[all_merge$value.pt==0 & all_merge$incident.death==0]     = 0
  adj_pe[all_merge$value.pt==0 & all_merge$incident.death==0] = 0
  pe[all_merge$value.pt!=0 & all_merge$incident.death==0]     = Inf
  
  ape              = abs(pe)
  adj_ape          = abs(adj_pe)
  logistic_ape     = 1 / (1 + exp(-ape/100))
  logistic_adj_ape = 1 / (1 + exp(-adj_ape/100))
  
  above = all_merge$incident.death > all_merge$value.0.975
  below = all_merge$incident.death < all_merge$value.0.025
  
  within_95_pi                             = rep(NA, nrow(all_merge))
  within_95_pi[which(above==F & below==F)] = "inside"
  within_95_pi[which(above==T)]            = "above"
  within_95_pi[which(below==T)]            = "below"
  
  outside_95p_by                             = rep(NA, nrow(all_merge))
  outside_95p_by[which(above==F & below==F)] = 0
  outside_95p_by[which(above==T)]            = all_merge$incident.death[which(above==T)] - all_merge$value.0.975[which(above==T)]
  outside_95p_by[which(below==T)]            = all_merge$incident.death[which(below==T)] - all_merge$value.0.025[which(below==T)]
  
  if(gt_source[i]=="JHU"){
    gt_jhu  = all_merge$incident.death
    gt_nyt  = NA
    gt_ecdc = NA
  }else if(gt_source[i]=="NYT"){
    gt_jhu  = NA
    gt_nyt  = all_merge$incident.death
    gt_ecdc = NA
  }else{
    gt_jhu  = NA
    gt_nyt  = NA
    gt_ecdc = all_merge$incident.death
  }
  
  df = data.frame(target_date      = all_merge$target_end_date, 
                  forecast_date    = all_merge$forecast_date, 
                  lookahead        = difftime(all_merge$target_end_date, all_merge$forecast_date, units="days"),
                  model_name       = model_name[i],
                  location_long    = location_long,
                  location_short   = location_short,
                  prediction_type  = "full_perc",
                  expected_value   = all_merge$value.pt,
                  perc_0.010       = all_merge$value.0.01,
                  perc_0.025       = all_merge$value.0.025,
                  perc_0.050       = all_merge$value.0.05,
                  perc_0.100       = all_merge$value.0.1,
                  perc_0.150       = all_merge$value.0.15,
                  perc_0.200       = all_merge$value.0.2,
                  perc_0.250       = all_merge$value.0.25,
                  perc_0.300       = all_merge$value.0.3,
                  perc_0.350       = all_merge$value.0.35,
                  perc_0.400       = all_merge$value.0.4,
                  perc_0.450       = all_merge$value.0.45,
                  perc_0.500       = all_merge$value.0.5,
                  perc_0.550       = all_merge$value.0.55,
                  perc_0.600       = all_merge$value.0.6,
                  perc_0.650       = all_merge$value.0.65,
                  perc_0.700       = all_merge$value.0.7,
                  perc_0.750       = all_merge$value.0.75,
                  perc_0.800       = all_merge$value.0.8,
                  perc_0.850       = all_merge$value.0.85,
                  perc_0.900       = all_merge$value.0.9,
                  perc_0.950       = all_merge$value.0.95,
                  perc_0.975       = all_merge$value.0.975,
                  perc_0.990       = all_merge$value.0.99,
                  gt_source        = gt_source[i],
                  gt_jhu           = gt_jhu,
                  gt_nyt           = gt_nyt,
                  gt_ecdc          = gt_ecdc,
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