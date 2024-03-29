# this is to format the raw estimation results by CU-60 to the format required

data_dir="../raw-data/IowaStateLW10/"
code_dir = "Data_formatting/"
source(paste0(code_dir,"IowaStateLW_convertor.R"))

files_in_dir = list.files(path= data_dir, pattern = '.csv')
library(tibble)
library(dplyr)

col_names=c("target_date",
            "forecast_date",
            "lookahead",
            "model_name",
            "location_long",
            "location_short",
            "prediction_type",
            "expected_value",
            "perc_0.010",
            "perc_0.025",
            "perc_0.050",
            "perc_0.100",
            "perc_0.150",
            "perc_0.200",
            "perc_0.250",
            "perc_0.300",
            "perc_0.350",
            "perc_0.400",
            "perc_0.450",
            "perc_0.500",
            "perc_0.550",
            "perc_0.600",
            "perc_0.650",
            "perc_0.700",
            "perc_0.750",
            "perc_0.800",
            "perc_0.850",
            "perc_0.900",
            "perc_0.950",
            "perc_0.975",
            "perc_0.990",
            "gt_source",
            "gt_jhu",
            "gt_nyt",
            "gt_ecdc",
            "error",
            "pe",
            "adj_pe",
            "ape",
            "adj_ape",
            "logistic_ape",
            "logistic_adj_ape",
            "within_95_pi",
            "outside_95p_by"
)

locations=c("Alabama",
            "Alaska",
            "Arizona",
            "Arkansas"
)

download.file("https://github.com/CSSEGISandData/COVID-19/raw/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv","jhu_truth.csv")
IowaStateLW10_processed=tibble()
for( i in files_in_dir){
  IowaStateLW10_processed=bind_rows(IowaStateLW10_processed,IowaStateLW_convertor(paste0(data_dir,i),col_names)) 
}
# calculate the performance indicators
IowaStateLW10_processed$error              = IowaStateLW10_processed$gt_jhu - IowaStateLW10_processed$expected_value 
IowaStateLW10_processed$pe                 = IowaStateLW10_processed$error/IowaStateLW10_processed$gt_jhu * 100
IowaStateLW10_processed$adj_pe             = IowaStateLW10_processed$error/(IowaStateLW10_processed$gt_jhu+ IowaStateLW10_processed$expected_value )* 100
IowaStateLW10_processed$ape                = abs(IowaStateLW10_processed$error)
IowaStateLW10_processed$adj_ape            = abs(IowaStateLW10_processed$adj_pe)
IowaStateLW10_processed$logistic_ape       = 1 / (1 + exp(-IowaStateLW10_processed$ape /100)) 
IowaStateLW10_processed$logistic_adj_ape   = 1 / (1 + exp(-IowaStateLW10_processed$adj_ape/100))

IowaStateLW10_processed$within_95_pi[IowaStateLW10_processed$prediction_type =="quantile"]              = "inside"
IowaStateLW10_processed$within_95_pi[IowaStateLW10_processed$gt_jhu > IowaStateLW10_processed$perc_0.975]       = "above"
IowaStateLW10_processed$within_95_pi[IowaStateLW10_processed$gt_jhu < IowaStateLW10_processed$perc_0.025]       = "below"

IowaStateLW10_processed$outside_95p_by[IowaStateLW10_processed$within_95_pi=="inside"]                  = 0

IowaStateLW10_processed[which((IowaStateLW10_processed$within_95_pi=="above")==T),"outside_95p_by"]                   = filter(IowaStateLW10_processed,within_95_pi=="above")$gt_jhu - filter(IowaStateLW10_processed,within_95_pi=="above")$perc_0.975

IowaStateLW10_processed[which((IowaStateLW10_processed$within_95_pi=="below")==T),"outside_95p_by"]                    = filter(IowaStateLW10_processed, within_95_pi=="below")$perc_0.025 - filter(IowaStateLW10_processed,within_95_pi=="below")$gt_jhu



write.csv(IowaStateLW10_processed, paste0(code_dir, "IowaStateLW10-processed.csv"), row.names = F)



