###############################################################################################################
# Script for standardising prediction data from Reich Lab Github page
###############################################################################################################

# Name of model and ground truth source
model     = c("NotreDame", "CovidActNow", "ERDC", "UChicago40", "UChicago60", "UChicago80", "UChicago100",
              "UChicago10increase", "UChicago30increase", "CU-60contact", "CU-70contact", "CU-80contact", 
              "CU-80contact1x10p", "CU-80contact1x5p", "CU-80contactw10p", "CU-80contactw5p", "CU-nointerv",
              "CU-select", "Imperial1", "Imperial2", "UA")
folder    = c("NotreDame", "CovidActNow", "ERDC", rep("UChicago", 6), rep("CU", 9), rep("Imperial", 2), "UA")
gt_source = c("NYT", "JHU", "JHU", rep("IDPH", 6), rep("USAFacts", 9), rep("ECDC", 2), "JHU")

# summary variable storing all prediction data
summary = c()

# Load csv files for the models, combine and convert into standardised format
for(i in 1:length(model)){
  setwd(paste0(wkdir, "/", folder[i]))
  summary = rbind.fill(summary, cbind(model_name=model[i], gt_source=gt_source[i], 
            ldply(list.files(pattern=paste0("^", model[i], "-(.*)csv$")), function(i) read.csv(i, stringsAsFactors=F, check.names=T))))
}
summary = summary %>% mutate(location_name=if_else(location=="US", "USA", location_name))

missing_loc = is.na(summary$location_name)
if(any(missing_loc)){
  code_table = rbind(usmap::fips_info(unique(summary$location[missing_loc])))
  summary$location_name[missing_loc] = mapvalues(summary$location[missing_loc], from=code_table$fips, to=code_table$full)
}

summary = summary %>%
          filter(grepl("day ahead inc death", target)) %>%
          select(ends_with("date"), model_name, location_short=location_name, quantile, value, gt_source) %>%
          replace_na(list(quantile="pt")) %>% 
          spread(quantile, value) %>%
          rename_at(vars(as.character(c(0.01, 0.025, seq(0.05, 0.95, 0.05), 0.975, 0.99, "pt"))), ~ 
                    c(paste0("perc_0.", formatC(c(10, 25, seq(50, 950, 50), 975, 990), width=3, flag="0")), "expected_value")) %>%
          dplyr::mutate(target_end_date=as.Date(target_end_date), forecast_date=as.Date(forecast_date), 
                 lookahead=target_end_date-forecast_date, location_short=mapvalues(location_short, 
                 from=c(state.name, "District of Columbia"), to=c(state.abb, "DC")), 
                 prediction_type=if_else(is.na(perc_0.500), "point_estimate", "full_perc")) %>%
          filter(lookahead>0, !is.nan(expected_value))
summary = summary[,c(2,1,30,3,4,31,29,6:28,5)]

# Save into summary folder
setwd(wkdir)
files_in_dir = list.files()
if(!"summary" %in% files_in_dir){
  dir.create("summary")
}
setwd(paste0(wkdir, "/summary/"))
print("Saving prediction data from Reich Lab Github page in summary folder")
write.csv(summary, "reich_lab_summary.csv", row.names = F)
setwd(wkdir)