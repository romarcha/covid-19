###############################################################################################################
# Script for standardising UT prediction data
###############################################################################################################

# Name of model and set working directory
model = "UT"
setwd(paste0(wkdir, "/", model))

# Load csv files for the model, combine and convert into standardised format
summary       = lapply(list.files(pattern=paste0("^", model, "(.*)csv$")), function(i) read.csv(i, stringsAsFactors=F, check.names=T))
forecast_date = as.Date(rep(str_extract(list.files(pattern=paste0("^", model, "(.*)csv$")), "[0-2]{4}[-][0-9]{2}[-][0-9]{2}"), unlist(lapply(summary, nrow)))) - 1
summary       = cbind(forecast_date=forecast_date, do.call(rbind.fill, summary))

summary = summary %>%
          select(ends_with("date"), location_short=state, starts_with("daily_deaths"), -daily_deaths_actual) %>%
          dplyr::mutate(date=as.Date(date), lookahead=date-forecast_date, model_name=model, location_short=case_when(is.na(location_short) ~ "USA", 
                        !is.na(location_short) ~ mapvalues(location_short, from=c(state.name, "District of Columbia"), to=c(state.abb, "DC"))),
                        prediction_type=if_else(!is.na(daily_deaths_90CI_lower), "90_PI", "95_PI"), gt_source=case_when(forecast_date <= as.Date("2020-05-05") ~ "NYT",
                        forecast_date > as.Date("2020-05-05") ~ "JHU"), perc_0.010=NA, perc_0.100=NA, perc_0.150=NA, perc_0.200=NA, perc_0.250=NA, perc_0.300=NA, 
                        perc_0.350=NA, perc_0.400=NA, perc_0.450=NA, perc_0.500=NA, perc_0.550=NA, perc_0.600=NA, perc_0.650=NA, perc_0.700=NA, perc_0.750=NA, 
                        perc_0.800=NA, perc_0.850=NA, perc_0.900=NA, perc_0.990=NA) %>%
          filter(forecast_date < date) %>%
          dplyr::rename_at(vars(c("date", "daily_deaths_est", "daily_deaths_90CI_lower", "daily_deaths_90CI_upper", "daily_deaths_95CI_lower", "daily_deaths_95CI_upper")),
                           ~ c("target_end_date", "expected_value", "perc_0.050", "perc_0.950", "perc_0.025", "perc_0.975"))
summary = summary[,c(2,1,9,10,3,11,4,13,7,5,14:30,6,8,31,12)]

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