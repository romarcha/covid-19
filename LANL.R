rm(list = ls())

# Installing required packages
packages = c("countrycode", "plyr", "dplyr", "downloader")
install.packages(packages)
lapply(packages, require, character.only = T)

# Path to working directory
wkdir = "~/Code/covid-19"

# Model name
model = c("LANL_global_inc", "LANL_states_inc")

for(i in 1:length(model)){
# Set working directory
setwd(paste0(wkdir, "/", model[i]))

# Ground truth source
gt_source = "JHU"

# Load all csv files in the model folder and combine all data
csv_file             = list.files(pattern=paste0("^", model[i], "(.*)csv$"))
prediction           = do.call(rbind.fill, lapply(1:length(csv_file), function(i) read.csv(csv_file[i])))
prediction$dates     = as.Date(prediction$dates)
prediction$fcst_date = as.Date(prediction$fcst_date)
prediction           = prediction[prediction$dates > prediction$fcst_date,]

# Rename column
if (model[i] == "LANL_global_inc"){
  names(prediction)[names(prediction) == "countries"] = "country"
}else{
  names(prediction)[names(prediction) == "state"] = "Province_State"
}

if (model[i] == "LANL_global_inc"){
  print("Downloading ground truth global data from JHU")
  download("https://github.com/CSSEGISandData/COVID-19/raw/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv",
           "jhu_truth.csv", quiet=T)
  jhu_truth = read.csv("jhu_truth.csv")
  jhu_truth = jhu_truth[jhu_truth$Province.State!="Recovered",]
  jhu_truth = aggregate(.~Country.Region, jhu_truth, sum)
  cum_death = jhu_truth[,5:ncol(jhu_truth)]
  inc_death = apply(cum_death, 1, diff)
  if (all(inc_death>=0)==F){
    warning("Negative incident deaths reported in ground truth data!")
  }
  jhu_truth = data.frame(country=rep(jhu_truth$Country.Region, each=nrow(inc_death)), 
                         dates=rep(seq(as.Date("2020-01-23"), as.Date("2020-01-23") + nrow(inc_death) - 1, by="days"), ncol(inc_death)),
                         incident.death=as.vector(inc_death))
  
  # Merging prediction with ground truth
  all_merge = join_all(list(prediction, jhu_truth), by=c("dates", "country"))
  
  # Location short and long. Manually adding Kosovo
  location_short = countrycode(all_merge$country, origin ="country.name", destination="iso3c")
  location_short[all_merge$country=="Kosovo"] = "KSV"
  location_long = countrycode(location_short, origin="iso3c", destination="country.name")
  location_long[is.na(location_long)] = "Kosovo"
}else{
  print("Downloading ground truth US states data from JHU")
  download("https://github.com/CSSEGISandData/COVID-19/raw/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv",
           "jhu_truth.csv", quiet=T)
  jhu_truth = read.csv("jhu_truth.csv")
  jhu_truth = jhu_truth[jhu_truth$Lat!=0 | jhu_truth$Long_!=0,]
  jhu_truth = aggregate(.~Province_State, jhu_truth, sum)
  cum_death = jhu_truth[,13:ncol(jhu_truth)]
  inc_death = apply(cum_death, 1, diff)
  if (all(inc_death>=0)==F){
    warning("Negative incident deaths reported in ground truth data!")
  }
  jhu_truth = data.frame(Province_State=rep(jhu_truth$Province_State, each=nrow(inc_death)), 
                         dates=rep(seq(as.Date("2020-01-23"), as.Date("2020-01-23") + nrow(inc_death) - 1, by="days"), ncol(inc_death)),
                         incident.death=as.vector(inc_death))
  
  # Merging prediction with ground truth
  all_merge = join_all(list(prediction, jhu_truth), by=c("dates", "Province_State"))
  
  # Location short and long. Changing Virgins Islands to U.S. Virgin Islands
  levels(all_merge$Province_State)[levels(all_merge$Province_State)=="Virgin Islands"] <- "U.S. Virgin Islands"
  location_short = mapvalues(all_merge$Province_State, from=c(state.name, "District of Columbia", "Puerto Rico", "U.S. Virgin Islands"), to=c(state.abb, "DC", "PRI", "VIR"))
  location_long  = all_merge$Province_State
}

# Calculating various measure
error  = all_merge$incident.death - all_merge$q.50
pe     = error/all_merge$incident.death * 100
adj_pe = error/(all_merge$incident.death + all_merge$q.50) * 100

pe[all_merge$q.50==0 & all_merge$incident.death==0]     = 0
adj_pe[all_merge$q.50==0 & all_merge$incident.death==0] = 0
pe[all_merge$q.50!=0 & all_merge$incident.death==0]     = Inf

ape              = abs(pe)
adj_ape          = abs(adj_pe)
logistic_ape     = 1 / (1 + exp(-ape/100))
logistic_adj_ape = 1 / (1 + exp(-adj_ape/100))

above = all_merge$incident.death > all_merge$q.975
below = all_merge$incident.death < all_merge$q.025

within_95_pi                                  = rep("inside", nrow(all_merge))
within_95_pi[is.na(all_merge$incident.death)] = NA
within_95_pi[which(above==T)]                 = "above"
within_95_pi[which(below==T)]                 = "below"

outside_95p_by                                  = rep(0, nrow(all_merge))
outside_95p_by[is.na(all_merge$incident.death)] = NA
outside_95p_by[which(above==T)]                 = all_merge$incident.death[which(above==T)] - 
                                                  all_merge$q.975[which(above==T)]
outside_95p_by[which(below==T)]                 = all_merge$incident.death[which(below==T)] - 
                                                  all_merge$q.025[which(below==T)]

df = data.frame(target_date      = all_merge$dates, 
                forecast_date    = all_merge$fcst_date, 
                lookahead        = difftime(all_merge$dates, all_merge$fcst_date, units="days"),
                model_name       = model[i],
                location_long    = location_long,
                location_short   = location_short,
                prediction_type  = "full_perc",
                expected_value   = all_merge$q.50,
                perc_0.010       = all_merge$q.01,
                perc_0.025       = all_merge$q.025,
                perc_0.050       = all_merge$q.05,
                perc_0.100       = all_merge$q.10,
                perc_0.150       = all_merge$q.15,
                perc_0.200       = all_merge$q.20,
                perc_0.250       = all_merge$q.25,
                perc_0.300       = all_merge$q.30,
                perc_0.350       = all_merge$q.35,
                perc_0.400       = all_merge$q.40,
                perc_0.450       = all_merge$q.45,
                perc_0.500       = all_merge$q.50,
                perc_0.550       = all_merge$q.55,
                perc_0.600       = all_merge$q.60,
                perc_0.650       = all_merge$q.65,
                perc_0.700       = all_merge$q.70,
                perc_0.750       = all_merge$q.75,
                perc_0.800       = all_merge$q.80,
                perc_0.850       = all_merge$q.85,
                perc_0.900       = all_merge$q.90,
                perc_0.950       = all_merge$q.95,
                perc_0.975       = all_merge$q.975,
                perc_0.990       = all_merge$q.99,
                gt_source        = gt_source,
                gt_jhu           = all_merge$incident.death,
                gt_nyt           = NA,
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