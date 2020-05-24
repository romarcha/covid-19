###############################################################################################################
# Script for standardising LANL prediction data
###############################################################################################################

# Name of model and set working directory
model = "LANL"
setwd(paste0(wkdir, "/", model))

# Ground truth source
gt_source = "JHU"

# Load csv files for the model, combine and convert into standardised format
summary_global = ldply(list.files(pattern=paste0("^", model, "_global_inc", "(.*)csv$")), function(i) read.csv(i, stringsAsFactors=F, check.names=F))
summary_global = summary_global %>%
                 dplyr::mutate(dates=as.Date(dates), fcst_date=as.Date(fcst_date), lookahead=dates-fcst_date, model_name=model,
                        countries=countrycode(countries, origin="country.name", destination="iso3c", nomatch=NULL), prediction_type="full_perc",
                        countries=gsub("Kosovo", "KSV", countries), expected_value=q.50, gt_source=gt_source) %>%
                 rename_at(vars(c("dates", "countries", "fcst_date", paste0("q.", c("01", "025", "05", seq(10, 95, 5), "975", "99")))), 
                           ~ c("target_end_date", "location_short", "forecast_date", paste0("perc_0.", formatC(c(10, 25, seq(50, 950, 50), 975, 990), width=3, flag="0")))) %>%
                 filter(lookahead>0)
summary_global = summary_global[,c(1,29:31,27,32,33,3:25,34)]


summary_us = ldply(list.files(pattern=paste0("^", model, "_states_inc", "(.*)csv$")), function(i) read.csv(i, stringsAsFactors=F, check.names=F))
summary_us = summary_us %>%
             dplyr::mutate(dates=as.Date(dates), fcst_date=as.Date(fcst_date), lookahead=dates-fcst_date, model_name=model,
                           state=mapvalues(state, from=c(state.name, "District of Columbia", "Puerto Rico", "Virgin Islands"), to=c(state.abb, "DC", "PRI", "VIR")),
                           prediction_type="full_perc", expected_value=q.50, gt_source=gt_source) %>%
             rename_at(vars(c("dates", "state", "fcst_date", paste0("q.", c("01", "025", "05", seq(10, 95, 5), "975", "99")))), 
                       ~ c("target_end_date", "location_short", "forecast_date", paste0("perc_0.", formatC(c(10, 25, seq(50, 950, 50), 975, 990), width=3, flag="0")))) %>%
             filter(lookahead>0)
summary_us = summary_us[,c(1,29:31,27,32,33,3:25,34)]

# Save into summary folder
setwd(wkdir)
files_in_dir = list.files()
if(!"summary" %in% files_in_dir){
  dir.create("summary")
}
setwd(paste0(wkdir, "/summary/"))
print(paste("Saving prediction data for model", model, "in summary folder"))
write.csv(rbind.fill(summary_global, summary_us), paste0(model, "_summary.csv"), row.names = F)
setwd(wkdir)