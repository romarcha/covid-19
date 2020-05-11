rm(list = ls())

# Installing required packages
packages = c("countrycode", "plyr", "dplyr", "downloader")
install.packages(packages)
lapply(packages, require, character.only = T)

# Path to working directory
wkdir = "~/Code/covid-19"

# Name of model and set working directory
model = "Geneva"
setwd(paste0(wkdir, "/", model))

# Ground truth source
gt_source = "ECDC"

# Load all csv files in the model folder and combine all data
csv_file      = list.files(pattern=paste0("^", model, "(.*)csv$"))
prediction    = lapply(1:length(csv_file), function(i) read.csv(csv_file[i]))
num_entry     = unlist(lapply(prediction, nrow))
forecast_date = rep(do.call(c, (lapply(1:length(csv_file), function(i) 
                max(as.Date(prediction[[i]]$date[prediction[[i]]$observed=="Observed"]))))), num_entry)
prediction    = cbind(forecast_date=forecast_date, do.call(rbind.fill, prediction))

# Rename column and remove rows with no predicted values, infinite deaths and forecast date is later than death reported date
names(prediction)[names(prediction) == "per.day"] = "pred.death"
prediction$date = as.Date(prediction$date)
prediction      = prediction[!is.na(prediction$pred.death) & is.finite(prediction$pred.death) & prediction$date > prediction$forecast_date,]

# Download ground truth value from ECDC website and renaming columns
print("Downloading ground truth global data from ECDC")
download("https://opendata.ecdc.europa.eu/covid19/casedistribution/csv", "ecdc_truth.csv", quiet=T)
ecdc_truth = read.csv("ecdc_truth.csv")
names(ecdc_truth)[names(ecdc_truth) == "dateRep"] = "date"
names(ecdc_truth)[names(ecdc_truth) == "countriesAndTerritories"] = "country"

ecdc_truth$country = as.factor(gsub("_", " ", ecdc_truth$country))
ecdc_truth$date    = as.Date(format(strptime(as.character(ecdc_truth$date), "%d/%m/%Y"), "%Y-%m-%d"))

# Merging prediction data with ground truth
all_merge = join_all(list(prediction, ecdc_truth), by=c("date", "country"))

# Location short and long. Manually adding Kosovo
location_short = countrycode(all_merge$country, origin ="country.name", destination="iso3c")
location_short[all_merge$country=="Kosovo"] = "KSV"
location_long = countrycode(location_short, origin="iso3c", destination="country.name")
location_long[is.na(location_long)] = "Kosovo"

# Calculating various measure
error  = all_merge$deaths - all_merge$pred.death
pe     = error/all_merge$deaths * 100
adj_pe = error/(all_merge$deaths + all_merge$pred.death) * 100

pe[all_merge$pred.death==0 & all_merge$deaths==0]     = 0
adj_pe[all_merge$pred.death==0 & all_merge$deaths==0] = 0
pe[all_merge$pred.death!=0 & all_merge$deaths==0]     = Inf

ape              = abs(pe)
adj_ape          = abs(adj_pe)
logistic_ape     = 1 / (1 + exp(-ape/100))
logistic_adj_ape = 1 / (1 + exp(-adj_ape/100))

above          = NA
below          = NA
within_95_pi   = NA
outside_95p_by = NA

df = data.frame(target_date      = all_merge$date, 
                forecast_date    = all_merge$forecast_date, 
                lookahead        = difftime(all_merge$date, all_merge$forecast_date, units="days"),
                model_name       = model,
                location_long    = location_long,
                location_short   = location_short,
                prediction_type  = "point_estimate",
                expected_value   = all_merge$pred.death,
                perc_0.010       = NA,
                perc_0.025       = NA,
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
                perc_0.975       = NA,
                perc_0.990       = NA,
                gt_source        = gt_source,
                gt_jhu           = NA,
                gt_nyt           = NA,
                gt_ecdc          = all_merge$deaths,
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