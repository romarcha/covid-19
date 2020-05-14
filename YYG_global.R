rm(list = ls())

# Installing required packages
packages = c("countrycode", "plyr", "dplyr")
install.packages(packages)
lapply(packages, require, character.only = T)

# Path to working directory
wkdir = "~/Code/covid-19"

# Name of model and set working directory
model = "YYG_global"
setwd(paste0(wkdir, "/", model))

# Ground truth source
gt_source = "JHU"

# Load all csv files in the model folder and combine all data
csv_file      = list.files(pattern=paste0("^", model, "(.*)csv$"))
prediction    = lapply(1:length(csv_file), function(i) read.csv(csv_file[i]))
num_entry     = unlist(lapply(prediction, nrow))
forecast_date = rep(do.call(c, (lapply(1:length(csv_file), function(i) 
                max(as.Date(prediction[[i]]$date[!is.na(prediction[[i]]$total_deaths)]))))), num_entry)
first_date    = do.call("c", lapply(1:length(csv_file), function(i) min(as.Date(prediction[[i]]$date))))
last_date     = do.call("c", lapply(1:length(csv_file), function(i) max(as.Date(prediction[[i]]$date))))
prediction    = cbind(forecast_date=forecast_date, do.call(rbind.fill, prediction))

# Latest death number provided by author in dataset
if(length(unique(num_entry))==1 & length(unique(first_date))==1 & length(unique(last_date))==1){
  death_to_date = apply(select(prediction[(nrow(prediction) - num_entry[1] + 1):nrow(prediction),], actual_deaths),
                  2, rep, length(csv_file))
}else{
  warning("Check YYG (Global) data standardisation code: size of each dataset is not the same.")
}

# Updating data with actual death number
prediction$actual_deaths = as.vector(death_to_date)
prediction               = prediction[!is.na(prediction$predicted_deaths_mean),]

# Calculating various measure
error  = prediction$actual_deaths - prediction$predicted_deaths_mean
pe     = error/prediction$actual_deaths * 100
adj_pe = error/(prediction$actual_deaths + prediction$predicted_deaths_mean) * 100

pe[prediction$predicted_deaths_mean==0 & prediction$actual_deaths==0]     = 0
adj_pe[prediction$predicted_deaths_mean==0 & prediction$actual_deaths==0] = 0
pe[prediction$predicted_deaths_mean!=0 & prediction$actual_deaths==0]     = Inf

ape              = abs(pe)
adj_ape          = abs(adj_pe)
logistic_ape     = 1 / (1 + exp(-ape/100))
logistic_adj_ape = 1 / (1 + exp(-adj_ape/100))

above = prediction$actual_deaths > prediction$predicted_deaths_upper
below = prediction$actual_deaths < prediction$predicted_deaths_lower

within_95_pi                             = rep(NA, nrow(prediction))
within_95_pi[which(above==F & below==F)] = "inside"
within_95_pi[which(above==T)]            = "above"
within_95_pi[which(below==T)]            = "below"

outside_95p_by                             = rep(NA, nrow(prediction))
outside_95p_by[which(above==F & below==F)] = 0
outside_95p_by[which(above==T)]            = prediction$actual_deaths[which(above==T)] - prediction$predicted_deaths_upper[which(above==T)]
outside_95p_by[which(below==T)]            = prediction$actual_deaths[which(below==T)] - prediction$predicted_deaths_lower[which(below==T)]

df = data.frame(target_date      = prediction$date, 
                forecast_date    = prediction$forecast_date, 
                lookahead        = difftime(as.Date(prediction$date), as.Date(prediction$forecast_date), units="days"),
                model_name       = "YYG",
                location_long    = prediction$country,
                location_short   = countrycode(prediction$country, origin="country.name", destination="iso3c"),
                prediction_type  = "95_PI",
                expected_value   = prediction$predicted_deaths_mean,
                perc_0.010       = NA,
                perc_0.025       = prediction$predicted_deaths_lower,
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
                perc_0.975       = prediction$predicted_deaths_upper,
                perc_0.990       = NA,
                gt_source        = gt_source,
                gt_jhu           = prediction$actual_deaths,
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

write.csv(df, paste0(model, "-summary.csv"), row.names = F)
setwd(wkdir)
rm(list = ls())