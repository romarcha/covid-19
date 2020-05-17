###############################################################################################################
# Script for standardising prediction data from Reich Lab Github page
###############################################################################################################

rm(list = ls())

# Installing required packages
packages = c("plyr", "dplyr", "tidyr")
if(!all(packages %in% rownames(installed.packages()))){
  install.packages(packages[!packages %in% rownames(installed.packages())])
}
lapply(packages, require, character.only = T)

# Path to directory
wkdir = "~/Code/covid-19"

# Name of model and ground truth source
model     = c("YYG", "NotreDame", "CovidActNow")
gt_source = c("JHU", "NYT", "JHU")

# summary variable storing all prediction data
summary = c()

# Load csv files for the models, combine and convert into standardised format
for(i in 1:length(model)){
  setwd(paste0(wkdir, "/", model[i]))
  pattern = ifelse(model[i]=="YYG", "_states", "")
  summary = rbind.fill(summary, cbind(model_name=model[i], gt_source=gt_source[i], 
            ldply(list.files(pattern=paste0("^", model[i], pattern, "(.*)csv$")), function(i) read.csv(i, stringsAsFactors=F, check.names=F))))
}

summary = summary %>%
          filter(grepl("day ahead inc death", target)) %>%
          select(ends_with("date"), model_name, location_short=location_name, quantile, value, gt_source) %>%
          replace_na(list(quantile="pt")) %>% 
          dplyr::mutate(target_end_date=as.Date(target_end_date), forecast_date=as.Date(forecast_date), 
                        lookahead=target_end_date-forecast_date, location_short=mapvalues(location_short, 
                        from=c(state.name, "District of Columbia", "Puerto Rico", "Virgin Islands", "US", 
                        "Guam", "Northern Mariana Islands"), to=c(state.abb, "DC", "PRI", "VIR", "USA", 
                        "GUM", "MNP")), prediction_type="full_perc") %>%
          spread(quantile, value) %>%
          rename_at(vars(as.character(c(0.01, 0.025, seq(0.05, 0.95, 0.05), 0.975, 0.99, "pt"))), ~ 
                    c(paste0("perc_0.", formatC(c(10, 25, seq(50, 950, 50), 975, 990), width=3, flag="0")), "expected_value"))
summary = summary[,c(2,1,6,3,4,7,31,8:30,5)]

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