rm(list = ls())

# Installing required packages
packages = c("countrycode", "plyr", "dplyr", "downloader")
install.packages(packages)
lapply(packages, require, character.only = T)

# Path to working directory
wkdir = "~/Code/covid-19"

# Name of model and set working directory
model = "IHME"
setwd(paste0(wkdir, "/", model))

# Ground truth source
gt_source = "JHU&NYT"

# Load all csv files in the model folder, standardising date variables, add forecast date and combine all data
csv_file   = list.files(pattern=paste0("^", model, "(.*)csv$"))
prediction = lapply(1:length(csv_file), function(i) read.csv(csv_file[i]))
for(i in 1:length(csv_file)){
  if("date_reported" %in% colnames(prediction[[i]])) colnames(prediction[[i]]) = mapvalues(colnames(prediction[[i]]), from="date_reported", to="date")
}
num_entry       = unlist(lapply(prediction, nrow))
forecast_date   = rep(as.Date(substring(csv_file, 6, 15))-1, num_entry)
prediction      = cbind(forecast_date, do.call(rbind.fill, prediction))
prediction$date = as.Date(prediction$date)

# Retain only US states and country
location  = unique(prediction$location_name)
us_states = c(state.name, "District of Columbia")
remaining = location[!location %in% us_states]
countries = countrycode(remaining, origin="country.name", destination="iso3c")
prediction$location_name = mapvalues(prediction$location_name, from=remaining[is.na(countries)], 
                                     to=rep("rest", length(remaining[is.na(countries)])))
prediction = prediction[prediction$location_name!="rest" & prediction$forecast_date < prediction$date,]

# JHU Global Data (remove Georgia (country) from data)
print("Downloading ground truth global data from JHU")
download("https://github.com/CSSEGISandData/COVID-19/raw/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv",
         "jhu_truth_global.csv", quiet=T)
jhu_truth_global = read.csv("jhu_truth_global.csv")
jhu_truth_global = jhu_truth_global[jhu_truth_global$Province.State!="Recovered",]
jhu_truth_global = jhu_truth_global[jhu_truth_global$Country.Region!="Georgia",]
jhu_truth_global = aggregate(.~Country.Region, jhu_truth_global, sum)
cum_death_global = jhu_truth_global[,5:ncol(jhu_truth_global)]
inc_death_global = apply(cum_death_global, 1, diff)
if (all(inc_death_global>=0)==F){
  warning("Negative incident deaths reported in ground truth data!")
}
jhu_truth_global = data.frame(location_name=rep(jhu_truth_global$Country.Region, each=nrow(inc_death_global)), 
                              date=rep(seq(as.Date("2020-01-23"), as.Date("2020-01-23") + nrow(inc_death_global) - 1, by="days"), ncol(inc_death_global)),
                              incident.death=as.vector(inc_death_global))

# JHU US States Data (remove New York from data)
print("Downloading ground truth US states data from JHU")
download("https://github.com/CSSEGISandData/COVID-19/raw/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv",
         "jhu_truth_states.csv", quiet=T)
jhu_truth_states = read.csv("jhu_truth_states.csv")
jhu_truth_states = jhu_truth_states[jhu_truth_states$Lat!=0 | jhu_truth_states$Long_!=0,]
jhu_truth_states = aggregate(.~Province_State, jhu_truth_states, sum)
jhu_truth_states = jhu_truth_states[jhu_truth_states$Province_State!="New York",]
cum_death_states = jhu_truth_states[,13:ncol(jhu_truth_states)]
inc_death_states = apply(cum_death_states, 1, diff)
if (all(inc_death_global>=0)==F){
  warning("Negative incident deaths reported in ground truth data!")
}
jhu_truth_states = data.frame(location_name=rep(jhu_truth_states$Province_State, each=nrow(inc_death_states)), 
                              date=rep(seq(as.Date("2020-01-23"), as.Date("2020-01-23") + nrow(inc_death_states) - 1, by="days"), ncol(inc_death_states)),
                              incident.death=as.vector(inc_death_states))

# NYT Data
print("Downloading ground truth New York data from NYT")
download("https://github.com/nytimes/covid-19-data/raw/master/us-states.csv", "nyt_truth.csv", quiet=T)
nyt_truth      = read.csv("nyt_truth.csv")
nyt_truth$date = as.Date(nyt_truth$date)
names(nyt_truth)[names(nyt_truth) == "state"] = "location_name"
names(nyt_truth)[names(nyt_truth) == "deaths"] = "incident.death"
nyt_truth = nyt_truth[nyt_truth$location_name=="New York",]
nyt_truth$incident.death = diff(c(0, nyt_truth$incident.death))
if (all(nyt_truth$incident.death>=0)==F){
  warning("Negative incident deaths reported in ground truth data!")
}

# Ground truth data from JHU global and US states and NYT
ground_truth = rbind.fill(jhu_truth_global, jhu_truth_states, nyt_truth)

# Merge all data based on location name and date
all_merge = join_all(list(prediction, ground_truth), by=c("location_name", "date"))

location_short = mapvalues(all_merge$location_name, from=c(state.name, "District of Columbia", as.character(remaining[!is.na(countries)])), to=c(state.abb, "DC", countries[!is.na(countries)]))
location_long  = mapvalues(all_merge$location_name, from=c("United States of America", "US"), to=rep("United States",2))

# Calculating various measure
error  = all_merge$incident.death - all_merge$deaths_mean
pe     = error/all_merge$incident.death * 100
adj_pe = error/(all_merge$incident.death + all_merge$deaths_mean) * 100

pe[all_merge$deaths_mean==0 & all_merge$incident.death==0]     = 0
adj_pe[all_merge$deaths_mean==0 & all_merge$incident.death==0] = 0
pe[all_merge$deaths_mean!=0 & all_merge$incident.death==0]     = Inf

ape              = abs(pe)
adj_ape          = abs(adj_pe)
logistic_ape     = 1 / (1 + exp(-ape/100))
logistic_adj_ape = 1 / (1 + exp(-adj_ape/100))

above = all_merge$incident.death > all_merge$deaths_upper
below = all_merge$incident.death < all_merge$deaths_lower

within_95_pi                                  = rep("inside", nrow(all_merge))
within_95_pi[is.na(all_merge$incident.death)] = NA
within_95_pi[which(above==T)]                 = "above"
within_95_pi[which(below==T)]                 = "below"

outside_95p_by                                  = rep(0, nrow(all_merge))
outside_95p_by[is.na(all_merge$incident.death)] = NA
outside_95p_by[which(above==T)]                 = all_merge$incident.death[which(above==T)] - 
                                                  all_merge$deaths_upper[which(above==T)]
outside_95p_by[which(below==T)]                 = all_merge$incident.death[which(below==T)] - 
                                                  all_merge$deaths_lower[which(below==T)]

df = data.frame(target_date      = all_merge$date, 
                forecast_date    = all_merge$forecast_date, 
                lookahead        = difftime(all_merge$date, all_merge$forecast_date, units="days"),
                model_name       = model,
                location_long    = location_long,
                location_short   = location_short,
                prediction_type  = "95PI",
                expected_value   = all_merge$deaths_mean,
                perc_0.010       = NA,
                perc_0.025       = all_merge$deaths_lower,
                perc_0.050       = NA,
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
                perc_0.950       = NA,
                perc_0.975       = all_merge$deaths_upper,
                perc_0.990       = NA,
                gt_source        = gt_source,
                gt_jhu           = all_merge$incident.death,
                gt_nyt           = all_merge$incident.death,
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
df$gt_jhu[df$location_short=="NY"] = NA
df$gt_nyt[df$location_short!="NY"] = NA

setwd(wkdir)

# Save data frame in summary folder
files_in_dir = list.files()
if("summary" %in% files_in_dir == F){
  dir.create("summary")
}
setwd(paste0(wkdir, "/summary/"))

write.csv(df, paste0(model, "-summary.csv"), row.names = F)
setwd(wkdir)
rm(list = ls())