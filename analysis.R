###############################################################################################################
# Script for analysing performance of various models
###############################################################################################################

rm(list = ls())

# Installing required packages
packages = c("dplyr")
if(!all(packages %in% rownames(installed.packages()))){
  install.packages(packages[!packages %in% rownames(installed.packages())])
}
lapply(packages, require, character.only = T)

# Path to directory
wkdir = "~/Code/covid-19/summary"
setwd(wkdir)

gt = read.csv("gt.csv", stringsAsFactors=F, check.names=F)
gt = gt %>% dplyr::rename(., target_end_date=date)

prediction = ldply(list.files(pattern=paste0("*_summary.csv$")), function(i) read.csv(i, stringsAsFactors=F, check.names=F))
prediction = prediction %>% 
             left_join(., gt, by=c("target_end_date", "location_short", "gt_source")) %>%
             mutate(error=inc.death-expected_value, pe=case_when(inc.death==0 & expected_value==0 ~ 0,
                                                                 inc.death==0 & expected_value!=0 ~ Inf,
                                                                 inc.death!=0 ~ error/inc.death*100),
                    adj_pe=case_when(inc.death==0 & expected_value==0 ~ 0,
                                     !(inc.death==0 & expected_value==0) ~ error/(inc.death + expected_value)*100),
                    ape=abs(pe), adj_ape=abs(adj_pe), logistic_ape=1/(1 + exp(-ape/100)), 
                    logistic_adj_ape=1/(1 + exp(-adj_ape/100)), within_95_pi=case_when(inc.death <= perc_0.975 & inc.death >= perc_0.025 ~ "inside",
                                                                                       inc.death > perc_0.975 ~ "above",
                                                                                       inc.death < perc_0.025 ~ "below"),
                    outside_95p_by=case_when(within_95_pi=="inside" ~ 0,
                                             within_95_pi=="above" ~ inc.death - perc_0.975,
                                             within_95_pi=="below" ~ inc.death - perc_0.025,),
                    gt_jhu=if_else(gt_source=="JHU", inc.death, NULL), gt_nyt=if_else(gt_source=="NYT", inc.death, NULL), gt_ecdc=if_else(gt_source=="ECDC", inc.death, NULL))
prediction = prediction[,c(1:4,32,5:31,44:46,35:43)]
print("Saving analysis of prediction data in summary folder")
write.csv(prediction, "analysis_result.csv", row.names = F)