# this is to format the raw estimation results by CU-80w to the format required


data_dir="../raw-data/Imperial2/"
code_dir = "Data_formatting/"
source(paste0(code_dir,"Imperial_convertor.R"))

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

# ECDC 
download.file("https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/ecdc/total_deaths.csv",'ecdc_truth.csv')
Imperial2_processed=tibble()
for( i in files_in_dir){
  Imperial2_processed=bind_rows(Imperial2_processed,Imperial_convertor(paste0(data_dir,i),col_names)) 
}
# calculate the performance indicators
Imperial2_processed$error              = Imperial2_processed$gt_jhu - Imperial2_processed$expected_value 
Imperial2_processed$pe                 = Imperial2_processed$error/Imperial2_processed$gt_jhu * 100
Imperial2_processed$adj_pe             = Imperial2_processed$error/(Imperial2_processed$gt_jhu+ Imperial2_processed$expected_value )* 100
Imperial2_processed$ape                = abs(Imperial2_processed$error)
Imperial2_processed$adj_ape            = abs(Imperial2_processed$adj_pe)
Imperial2_processed$logistic_ape       = 1 / (1 + exp(-Imperial2_processed$ape /100)) 
Imperial2_processed$logistic_adj_ape   = 1 / (1 + exp(-Imperial2_processed$adj_ape/100))

Imperial2_processed$within_95_pi[Imperial2_processed$prediction_type =="quantile"]              = "inside"
Imperial2_processed$within_95_pi[Imperial2_processed$gt_jhu > Imperial2_processed$perc_0.975]       = "above"
Imperial2_processed$within_95_pi[Imperial2_processed$gt_jhu < Imperial2_processed$perc_0.025]       = "below"

Imperial2_processed$outside_95p_by[Imperial2_processed$within_95_pi=="inside"]                  = 0

Imperial2_processed[which((Imperial2_processed$within_95_pi=="above")==T),"outside_95p_by"]                   = filter(Imperial2_processed,within_95_pi=="above")$gt_jhu - filter(Imperial2_processed,within_95_pi=="above")$perc_0.975

Imperial2_processed[which((Imperial2_processed$within_95_pi=="below")==T),"outside_95p_by"]                    = filter(Imperial2_processed, within_95_pi=="below")$perc_0.025 - filter(Imperial2_processed,within_95_pi=="below")$gt_jhu



write.csv(Imperial2_processed, paste0(code_dir, "Imperial2-processed.csv"), row.names = F)









