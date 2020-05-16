###############################################################################################################
# Script for standardising Geneva prediction data
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
model = "Geneva"
setwd(paste0(wkdir, "/", model))

# Ground truth source
gt_source = "ECDC"

# Load csv files for the model, combine and convert into standardised format
summary       = lapply(list.files(pattern=paste0("^", model, "(.*)csv$")), function(i) read.csv(i, stringsAsFactors=F, check.names=T))
forecast_date = rep(str_extract(list.files(pattern=paste0("^", model, "(.*)csv$")), "[0-2]{4}[-][0-9]{2}[-][0-9]{2}"), unlist(lapply(summary, nrow)))
summary       = cbind(forecast_date=forecast_date, do.call(rbind.fill, summary))

summary = summary %>%
          filter(observed=="Predicted", is.finite(per.day), !is.na(per.day)) %>%
          select(target_end_date=date, forecast_date=forecast_date, location_short=country, expected_value=per.day) %>%
          dplyr::mutate(target_end_date=as.Date(target_end_date), forecast_date=as.Date(forecast_date),
                 forecast_date=case_when(forecast_date==target_end_date ~ forecast_date-1, forecast_date<target_end_date ~ forecast_date),
                 lookahead=target_end_date-forecast_date, model_name=model, prediction_type="point_estimate", gt_source=gt_source,
                 location_short=countrycode(gsub("CuraÃ§ao", "Curaçao", location_short), origin="country.name", destination="iso3c", nomatch=NULL),
                 location_short=gsub("Kosovo", "KSV", location_short), perc_0.010=NA, perc_0.025=NA, perc_0.050=NA, perc_0.100=NA, perc_0.150=NA, 
                 perc_0.200=NA, perc_0.250=NA, perc_0.300=NA, perc_0.350=NA, perc_0.400=NA, perc_0.450=NA, perc_0.500=NA, perc_0.550=NA, 
                 perc_0.600=NA, perc_0.650=NA, perc_0.700=NA, perc_0.750=NA, perc_0.800=NA, perc_0.850=NA, perc_0.900=NA, perc_0.950=NA, 
                 perc_0.975=NA, perc_0.990=NA)
summary = summary[,c(1,2,5,6,3,7,4,9:31,8)]

# Save into summary folder
setwd(wkdir)
files_in_dir = list.files()
if(!"summary" %in% files_in_dir){
  dir.create("summary")
}
setwd(paste0(wkdir, "/summary/"))
print(paste("Saving prediction data for model", model, "in summary folder"))
write.csv(summary, paste0(model, "_summary.csv"), row.names = F)
setwd(wkdir)