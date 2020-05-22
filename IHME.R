###############################################################################################################
# Script for standardising IHME prediction data
###############################################################################################################

# Name of model and set working directory
model = "IHME"
setwd(paste0(wkdir, "/", model))

# Load csv files for the model, combine and convert into standardised format
summary     = lapply(list.files(pattern=paste0("^", model, "(.*)csv$")), function(i) read.csv(i, stringsAsFactors=F, check.names=T))     
report_date = as.Date(rep(str_extract(list.files(pattern=paste0("^", model, "(.*)csv$")), "[0-2]{4}[-][0-9]{2}[-][0-9]{2}"), unlist(lapply(summary, nrow))))
summary     = cbind(df.id=rep(1:length(summary), unlist(lapply(summary, nrow))), report_date=report_date, do.call(rbind.fill, summary)) 

# Only retain prediction data for country/US states
loc_name     = unique(summary$location_name) 
loc_name_abb = loc_name %>%
               mapvalues(., from=c(state.name, "District of Columbia", "Mexico City", "State of Mexico"), to=c(state.abb, "DC", rep("Subnational", 2))) %>%
               countrycode(., origin="country.name", destination="iso3c", nomatch=NULL)
summary      = summary %>%
               dplyr::mutate(date=case_when(is.na(date) ~ as.Date(date_reported), is.na(date_reported) ~ as.Date(date)),
                      model_name="IHME", location_name=mapvalues(location_name, loc_name, loc_name_abb), prediction_type="95_PI",
                      gt_source=case_when(location_name=="NY" ~ "NYT", location_name=="IL" ~ "IDPH", !location_name %in% c("IL", "NY") ~ "JHU")) %>%
               select(df.id, report_date, target_end_date=date, model_name, location_short=location_name, prediction_type, expected_value=deaths_mean, 
                      perc_0.025=deaths_lower, perc_0.975=deaths_upper, -ends_with("smoothed"), -starts_with("totdea"), gt_source) %>%
               filter(target_end_date > as.Date("2020-03-22"), nchar(location_short) <= 3) %>%
               group_by(location_short, df.id) %>%
               dplyr::mutate(max_int_date = if(length(target_end_date[target_end_date <= report_date & (expected_value%%1==0 | perc_0.975-perc_0.025<0.01)])==0) 
                      report_date else max(target_end_date[target_end_date <= report_date & (expected_value%%1==0 | perc_0.975-perc_0.025<0.01)]),
                      forecast_date=min(c(report_date, max_int_date))) %>%
               as.data.frame()
              
# Determine distinct prediction data for country/US states           
distinct_pred = summary %>%
                group_by(location_short, target_end_date) %>%
                distinct_at(vars("expected_value", starts_with("perc")), .keep_all=T) %>%
                ungroup() %>%
                group_by(location_short) %>%
                distinct(., df.id) %>%
                as.data.frame()

summary_distinct = c()
loc_name_abb     = unique(loc_name_abb[nchar(loc_name_abb)<=3])
for(i in 1:length(loc_name_abb)){
  summary_distinct = rbind.fill(summary_distinct, summary %>% filter(location_short==loc_name_abb[i], 
                                df.id %in% (distinct_pred %>% filter(location_short==loc_name_abb[i]) %>% select(df.id) %>% unlist())))
}
 
# Convert into standardised format
summary_distinct = summary_distinct %>%
                   filter(target_end_date > forecast_date) %>%
                   dplyr::mutate(lookahead=target_end_date-forecast_date, perc_0.010=NA, perc_0.050=NA, perc_0.100=NA, perc_0.150=NA, perc_0.200=NA, perc_0.250=NA, 
                                 perc_0.300=NA, perc_0.350=NA, perc_0.400=NA, perc_0.450=NA, perc_0.500=NA, perc_0.550=NA, perc_0.600=NA, perc_0.650=NA, 
                                 perc_0.700=NA, perc_0.750=NA, perc_0.800=NA, perc_0.850=NA, perc_0.900=NA, perc_0.950=NA, perc_0.990=NA)
summary_distinct = summary_distinct[,c(3,12,13,4:7,14,8,15:33,9,34,10)]

# Save into summary folder
setwd(wkdir)
files_in_dir = list.files()
if(!"summary" %in% files_in_dir){
  dir.create("summary")
}
setwd(paste0(wkdir, "/summary/"))
print(paste("Saving prediction data for model", model, "in summary folder"))
write.csv(summary_distinct, paste0(model, "_summary.csv"), row.names = F)
setwd(wkdir)