###############################################################################################################
# Script for standardising YYG prediction data
###############################################################################################################

rm(list = ls())

# Installing required packages
packages = c("countrycode", "plyr", "dplyr", "stringr")
if(!all(packages %in% rownames(installed.packages()))){
  install.packages(packages[!packages %in% rownames(installed.packages())])
}
lapply(packages, require, character.only = T)

# Path to directory
wkdir = "~/Code/covid-19"

# Name of model and set working directory
model = "YYG"
setwd(paste0(wkdir, "/", model))

# Ground truth source
gt_source = "JHU"

# Load csv files for the model, combine and convert into standardised format
summary       = lapply(list.files(pattern=paste0("^", model, "_global", "(.*)csv$")), function(i) read.csv(i, stringsAsFactors=F, check.names=F))
forecast_date = rep(str_extract(list.files(pattern=paste0("^", model, "_global", "(.*)csv$")), "[0-2]{4}[-][0-9]{2}[-][0-9]{2}"), unlist(lapply(summary, nrow)))
summary       = cbind(forecast_date=forecast_date, do.call(rbind.fill, summary))

summary = summary %>%
          filter(!is.na(predicted_deaths_mean)) %>%
          select(ends_with("date"), country, starts_with("predicted_deaths")) %>%
          dplyr::rename(., target_end_date=date, location_short=country, perc_0.025=predicted_deaths_lower, perc_0.500=predicted_deaths_mean, perc_0.975=predicted_deaths_upper) %>%
          dplyr::mutate(lookahead=as.Date(target_end_date)-as.Date(forecast_date), model_name=model, location_short=countrycode(location_short, origin="country.name", destination="iso3c"),
                 prediction_type="95_PI", expected_value=perc_0.500, perc_0.010=NA, perc_0.050=NA, perc_0.100=NA, perc_0.150=NA, perc_0.200=NA, perc_0.250=NA, perc_0.300=NA, 
                 perc_0.350=NA, perc_0.400=NA, perc_0.450=NA, perc_0.550=NA, perc_0.600=NA, perc_0.650=NA, perc_0.700=NA, perc_0.750=NA, perc_0.800=NA, perc_0.850=NA, perc_0.900=NA, 
                 perc_0.950=NA, perc_0.990=NA, gt_source=gt_source)
summary = summary[,c(2,1,7,8,3,9:11,5,12:20,4,21:29,6,30,31)]

# Save into summary folder
setwd(wkdir)
files_in_dir = list.files()
if(!"summary" %in% files_in_dir){
  dir.create("summary")
}
setwd(paste0(wkdir, "/summary/"))
print(paste("Saving prediction data for model", model, "in summary folder"))
write.csv(summary, paste0(model, "_global_summary.csv"), row.names = F)
setwd(wkdir)