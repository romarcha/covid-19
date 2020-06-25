###############################################################################################################
# Script for standardising YYG prediction data
###############################################################################################################

# Name of model and set working directory
model = "YYG"
setwd(paste0(wkdir, "/", model))

# Ground truth source
gt_source = "JHURD"

# Load csv files for the model, combine and convert into standardised format
summary       = lapply(list.files(pattern=paste0("^", model, "(.*)csv$")), function(i) read.csv(i, stringsAsFactors=F, check.names=F))
forecast_date = rep(str_extract(list.files(pattern=paste0("^", model, "(.*)csv$")), "[0-2]{4}[-][0-9]{2}[-][0-9]{2}"), unlist(lapply(summary, nrow)))
summary       = cbind(forecast_date=forecast_date, do.call(rbind.fill, summary))

summary = summary %>%
          select(ends_with("date"), country, region, starts_with("predicted_deaths")) %>%
          dplyr::rename(., target_end_date=date, location_short=country, perc_0.025=predicted_deaths_lower, expected_value=predicted_deaths_mean, perc_0.975=predicted_deaths_upper) %>%
          dplyr::mutate(lookahead=as.Date(target_end_date)-as.Date(forecast_date), model_name=model, location_short=if_else(nchar(region)==2, mapvalues(region, 
                 from=c("AS", "GU", "MP", "PR", "VI"), to=c("ASM", "GUM", "MNP", "PRI", "VIR")), countrycode(location_short, origin="country.name", destination="iso3c")), 
                 prediction_type="95_PI", expected_value=if_else(is.na(expected_value), predicted_deaths, expected_value), perc_0.010=NA, perc_0.050=NA, perc_0.100=NA, perc_0.150=NA, 
                 perc_0.200=NA, perc_0.250=NA, perc_0.300=NA, perc_0.350=NA, perc_0.400=NA, perc_0.450=NA, perc_0.500=NA, perc_0.550=NA, perc_0.600=NA, perc_0.650=NA, perc_0.700=NA, 
                 perc_0.750=NA, perc_0.800=NA, perc_0.850=NA, perc_0.900=NA, perc_0.950=NA, perc_0.990=NA, gt_source=gt_source) %>%
          filter(lookahead>0, !is.na(expected_value))
summary = summary[,c(2,1,9,10,3,11,5,12,6,13:31,7,32,33)]

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