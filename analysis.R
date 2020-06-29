###############################################################################################################
# Script for analysing performance of various models
###############################################################################################################

# Path to directory
setwd(paste0(wkdir, "/summary/"))

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
                                             within_95_pi=="below" ~ inc.death - perc_0.025)) %>%
              dplyr::rename(., gt=inc.death)

loc_short                = unique(prediction$location_short)
loc_long                 = countrycode(loc_short, origin="iso3c", destination="country.name", nomatch=NULL)
loc_long                 = mapvalues(loc_long, from=c(state.abb, "DC"), to=c(state.name, "District of Columbia"))
prediction$location_long = mapvalues(prediction$location_short, from=loc_short, to=loc_long)
prediction               = prediction[,c(1:4,32,5:31,34:43)]
prediction_us            = prediction[nchar(prediction$location_short)==2|prediction$location_short=="USA",]
prediction_rest_of_world = prediction[nchar(prediction$location_short)==3&prediction$location_short!="USA",]

print("Saving analysis of prediction data (US and states) in summary folder")
write.csv(prediction_us, "us_result.csv", row.names = F)

print("Saving analysis of prediction data (rest of the world) in summary folder")
write.csv(prediction_rest_of_world, "world_result.csv", row.names = F)
setwd(wkdir)