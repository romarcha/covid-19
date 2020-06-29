library(plyr)
library(dplyr)
library(ggplot2)
setwd("~/Code/covid-19/NY/")
gt      = read.csv("ny_gt.csv", stringsAsFactors=F)
data_ny = read.csv("ny_data.csv", stringsAsFactors=F)

gt = gt %>%
  dplyr::mutate(target_end_date=as.Date(target_end_date))

data_ny = data_ny %>%
  dplyr::mutate(forecast_date=as.Date(forecast_date), target_end_date=as.Date(target_end_date))

### Comparison of ground truth between different sources
ggplot(gt, aes(x=target_end_date, y=gt, color=gt_source)) +
  geom_line() +
  geom_point(size=0.5) +
  xlab("Target date") +
  ylab("Death counts") +
  scale_color_manual(name="Ground truth",
                     labels=c("CovidTracking", "JHURD", "JHUTS", "NYT", "USAFacts"),
                     values=c("black", "red", "blue", "green", "cyan")) +
  theme_bw() +
  theme(axis.title=element_text(size=18),
        axis.text=element_text(size=16),
        legend.title=element_text(size=18),
        legend.text=element_text(size=16))

### Comparison between forecast series and training ground truth for each model
training_gt = rbind.fill(cbind(model_name="IHME", period=1, gt %>% filter(gt_source=="NYT")),
                         cbind(model_name="LANL", period=1, gt %>% filter(gt_source=="JHURD")),
                         cbind(model_name="UT", period=1, gt %>% filter(gt_source=="NYT", target_end_date<=as.Date("2020-05-04"))),
                         cbind(model_name="UT", period=2, gt %>% filter(gt_source=="JHUTS")),
                         cbind(model_name="YYG", period=1, gt %>% filter(gt_source=="JHURD"))
                         )

ggplot(data_ny, aes(x=target_end_date, y=expected_value, color=as.factor(forecast_date))) +
  geom_line() + 
  xlab("Target date") +
  ylab("Death counts") +
  coord_cartesian(ylim=c(0, 1600)) +
  scale_colour_manual(values=rainbow(length(unique(data_ny$forecast_date)), start=0, end=0.8)) +
  geom_line(data=subset(training_gt, period==1) %>% dplyr::rename(., expected_value=gt), colour="black") +
  geom_line(data=subset(training_gt, period==2) %>% dplyr::rename(., expected_value=gt), colour="gray70") +
  facet_wrap(~model_name, labeller=as_labeller(c(`IHME`="IHME (NYT)", `LANL`="LANL (JHURD)", `UT`="UT (NYT and JHUTS)", `YYG`="YYG (JHURD)"))) +
  theme_bw() +
  theme(legend.position="none",
        axis.title=element_text(size=16),
        axis.text=element_text(size=14),
        strip.text=element_text(size=14))

### Point estimates and 95% PI
forecast_1_14 = data_ny %>%
  filter(lookahead<=14, target_end_date<=as.Date("2020-06-05")) %>%
  left_join(., gt, by=c("target_end_date", "location_long", "location_short", "gt_source")) %>%
  tidyr::drop_na(lb_95pi)
limits = c(min(forecast_1_14$lb_95pi), max(forecast_1_14$ub_95pi))

ggplot(forecast_1_14 %>% filter(lookahead<=7), aes(x=target_end_date, y=expected_value)) +
  geom_point(size=0.5) +
  geom_errorbar(aes(ymin=lb_95pi, ymax=ub_95pi), width=2, alpha=0.35) +
  xlab("Target date") +
  ylab("Death counts based on training ground truth") +
  coord_cartesian(xlim=as.Date(c("2020-03-25", "2020-06-05")), ylim=limits) +
  facet_grid(model_name~lookahead, labeller=as_labeller(c(`IHME`="IHME (NYT)", `LANL`="LANL (JHURD)", `UT`="UT (NYT and JHUTS)", `YYG`="YYG (JHURD)", `1`=1, `2`=2, `3`=3, `4`=4, `5`=5, `6`=6, `7`=7))) +
  geom_point(data=forecast_1_14 %>% filter(lookahead<=7) %>% select(target_end_date, model_name, lookahead, gt) %>% dplyr::rename(., expected_value=gt), colour="red", size=0.5) +
  theme_bw()+
  theme(axis.title=element_text(size=16),
        axis.text.y=element_text(size=14),
        axis.text.x=element_text(size=14, angle=90),
        strip.text=element_text(size=10))

ggplot(forecast_1_14 %>% filter(lookahead>7), aes(x=target_end_date, y=expected_value)) +
  geom_point(size=0.5) +
  geom_errorbar(aes(ymin=lb_95pi, ymax=ub_95pi), width=2, alpha=0.35) +
  xlab("Target date") +
  ylab("Death counts based on training ground truth") +
  coord_cartesian(xlim=as.Date(c("2020-03-25", "2020-06-05")), ylim=limits) +
  facet_grid(model_name~lookahead, labeller=as_labeller(c(`IHME`="IHME (NYT)", `LANL`="LANL (JHURD)", `UT`="UT (NYT and JHUTS)", `YYG`="YYG (JHURD)", `8`=8, `9`=9, `10`=10, `11`=11, `12`=12, `13`=13, `14`=14))) +
  geom_point(data=forecast_1_14 %>% filter(lookahead>7) %>% select(target_end_date, model_name, lookahead, gt) %>% dplyr::rename(., expected_value=gt), colour="red", size=0.5) +
  theme_bw()+
  theme(axis.title=element_text(size=16),
        axis.text.y=element_text(size=14),
        axis.text.x=element_text(size=14, angle=90),
        strip.text=element_text(size=10))

### Performance measure
forecast_training = left_join(data_ny %>% filter(target_end_date<=as.Date("2020-06-05")), gt, by=c("target_end_date", "location_long", "location_short", "gt_source")) %>% dplyr::mutate(gt_source="Training")
forecast_diff_gt = inner_join(data_ny %>% select(-gt_source), gt %>% filter(!gt_source %in% c("CovidTracking", "USAFacts"), target_end_date>=as.Date("2020-03-25")), by=c("target_end_date", "location_long", "location_short"))
forecast_combined = plyr::rbind.fill(forecast_training, forecast_diff_gt)

shortest_series = forecast_combined %>%
  group_by(model_name, forecast_date) %>%
  dplyr::summarise(max_k_step=max(lookahead)) %>%
  ungroup() %>%
  group_by(forecast_date) %>%
  dplyr::summarise(min_k_step=min(max_k_step)) %>%
  ungroup()

forecast_combined = forecast_combined %>%
  left_join(., shortest_series, by="forecast_date") %>% 
  filter(lookahead<=min_k_step) %>%
  dplyr::mutate(error=gt-expected_value, pe=error/gt*100, within_95_pi=if_else(gt>ub_95pi, "above", if_else(gt<lb_95pi, "below", "within")))

perf_comp = forecast_combined %>%
  group_by(forecast_date, model_name, gt_source) %>%
  dplyr::summarise(mean_ape=mean(abs(pe)), max_ape=max(abs(pe))) %>%
  ungroup()

perf_comp = cbind(do.call("rbind", replicate(2, perf_comp[,1:3], simplify=F)), val=c(perf_comp$mean_ape, perf_comp$max_ape), measure=rep(c("Mean APE", "Max APE"), each=nrow(perf_comp)))

ggplot(perf_comp, aes(x=forecast_date, y=val, color=model_name)) +
  geom_line() +
  geom_point(size=0.5) +
  xlab("Forecast date") +
  ylab("Value") +
  scale_color_manual(name="Model",
                     labels=c("IHME","LANL","UT", "YYG"),
                     values=c("#F8766D","#7CAE00", "#00BFC4", "#C77CFF")) +
  facet_grid(measure~gt_source, scales="free_y") +
  theme_bw() +
  theme(axis.title = element_text(size = 16),
        axis.text.y = element_text(size = 12),
        axis.text.x = element_text(size = 12, angle=90),
        strip.text = element_text(size=14),
        legend.text = element_text(size=10),
        legend.title = element_text(size=12))

### Within/above/below 95% PIs and prediction within +/- 10% of ground truth
perc_comp = forecast_combined %>%
  filter(lookahead<=14) %>%
  tidyr::drop_na(lb_95pi) %>%
  group_by(lookahead, model_name, gt_source) %>%
  dplyr::summarise(inside=sum(within_95_pi=="within")/length(within_95_pi)*100, out.ab=sum(within_95_pi=="above")/length(within_95_pi)*100, out.bel=100-inside-out.ab, within_pm10=sum(abs(pe)<=10)/length(pe)*100) %>%
  ungroup()

perc_comp = cbind(do.call("rbind", replicate(4, perc_comp[,1:3], simplify=F)), val=c(perc_comp$inside, perc_comp$out.ab, perc_comp$out.bel, perc_comp$within_pm10), measure=rep(c("inside", "out.above", "out.below", "within.pm10"), each=nrow(perc_comp)))

ggplot(perc_comp, aes(x=lookahead, y=val, color=model_name)) +
  geom_line() +
  geom_point(size=0.5) +
  xlab("Forecast date") +
  ylab("Value") +
  scale_color_manual(name="Model",
                     labels=c("IHME","LANL","UT", "YYG"),
                     values=c("#F8766D","#7CAE00", "#00BFC4", "#C77CFF")) +
  facet_grid(measure~gt_source, scales="free_y", labeller=as_labeller(c(`Training`="Training ground truth", `NYT`="NYT ground truth", `JHUTS`="JHUTS ground truth", `JHURD`="JHURD ground truth", `inside`="Within 95% PI", `out.above`="Above 95% PI", `out.below`="Below 95% PI", `within.pm10`="APE \u2264 10%"))) +
  theme_bw() +
  theme(axis.title = element_text(size = 16),
        axis.text.y = element_text(size = 12),
        axis.text.x = element_text(size = 12, angle=90),
        strip.text = element_text(size=14),
        legend.text = element_text(size=10),
        legend.title = element_text(size=12))

### Some statistics
forecast_combined = forecast_combined %>%
  tidyr::drop_na(lb_95pi) %>%
  filter(lookahead<=14, gt_source=="Training")

percentage = forecast_combined %>%
  filter(between(forecast_date, as.Date("2020-03-24"), as.Date("2020-03-31")), model_name=="IHME") %>%
  dplyr::summarise(val=sum(within_95_pi!="within")/length(within_95_pi)*100)
print(paste0("Percentage of predictions outside 95% PIs for IHME over the forecast period Mar 24 to Mar 31 is ", formatC(as.numeric(percentage), format="f", digits=1), "%"))

percentage = forecast_combined %>%
  filter(between(forecast_date, as.Date("2020-04-03"), as.Date("2020-05-03")), model_name=="IHME") %>%
  dplyr::summarise(val=sum(within_95_pi!="within")/length(within_95_pi)*100)
print(paste0("Percentage of predictions outside 95% PIs for IHME over the forecast period Apr 3 to May 3 is ", formatC(as.numeric(percentage), format="f", digits=1), "%"))

percentage = forecast_combined %>%
  filter(forecast_date>=as.Date("2020-05-04"), model_name=="IHME") %>%
  dplyr::summarise(val=sum(within_95_pi!="within")/length(within_95_pi)*100)
print(paste0("Percentage of predictions outside 95% PIs for IHME over the forecast period May 4 on-wards is ", formatC(as.numeric(percentage), format="f", digits=1), "%"))

percentage = forecast_combined %>%
  filter(model_name=="YYG") %>%
  dplyr::summarise(val=sum(within_95_pi!="within")/length(within_95_pi)*100)
print(paste0("Percentage of predictions outside 95% PIs for YYG across the entire time period is ", formatC(as.numeric(percentage), format="f", digits=1), "%"))

percentage = forecast_combined %>%
  filter(lookahead==1, model_name=="YYG", forecast_date>=as.Date("2020-05-01")) %>%
  dplyr::summarise(val=sum(within_95_pi!="within")/length(within_95_pi)*100)
print(paste0("Percentage of 1-step-ahead predictions outside 95% PIs for YYG over the forecast period May 1 on-wards is ", formatC(as.numeric(percentage), format="f", digits=1), "%"))

percentage = forecast_combined %>%
  filter(lookahead==14, model_name=="YYG", forecast_date>=as.Date("2020-05-01")) %>%
  dplyr::summarise(val=sum(within_95_pi!="within")/length(within_95_pi)*100)
print(paste0("Percentage of 14-step-ahead predictions outside 95% PIs for YYG over the forecast period May 1 on-wards is ", formatC(as.numeric(percentage), format="f", digits=1), "%"))

percentage = forecast_combined %>%
  filter(lookahead==1, model_name=="YYG", forecast_date<as.Date("2020-05-01")) %>%
  dplyr::summarise(val=sum(within_95_pi!="within")/length(within_95_pi)*100)
print(paste0("Percentage of 1-step-ahead predictions outside 95% PIs for YYG over the forecast period before May 1 is ", formatC(as.numeric(percentage), format="f", digits=1), "%"))

percentage = forecast_combined %>%
  filter(lookahead==14, model_name=="YYG", forecast_date<as.Date("2020-05-01")) %>%
  dplyr::summarise(val=sum(within_95_pi!="within")/length(within_95_pi)*100)
print(paste0("Percentage of 14-step-ahead predictions outside 95% PIs for YYG over the forecast period before May 1 is ", formatC(as.numeric(percentage), format="f", digits=1), "%"))

percentage = forecast_combined %>%
  filter(lookahead==1, model_name=="UT") %>%
  dplyr::summarise(val=sum(within_95_pi!="within")/length(within_95_pi)*100)
print(paste0("Percentage of 1-step-ahead predictions outside 95% PIs for UT across the entire time period is ", formatC(as.numeric(percentage), format="f", digits=1), "%"))

percentage = forecast_combined %>%
  filter(lookahead==14, model_name=="UT") %>%
  dplyr::summarise(val=sum(within_95_pi!="within")/length(within_95_pi)*100)
print(paste0("Percentage of 14-step-ahead predictions outside 95% PIs for UT across the entire time period is ", formatC(as.numeric(percentage), format="f", digits=1), "%"))

percentage = forecast_combined %>%
  filter(lookahead==1, model_name=="LANL") %>%
  dplyr::summarise(val=sum(within_95_pi!="within")/length(within_95_pi)*100)
print(paste0("Percentage of 1-step-ahead predictions outside 95% PIs for LANL across the entire time period is ", formatC(as.numeric(percentage), format="f", digits=1), "%"))

percentage = forecast_combined %>%
  filter(lookahead==14, model_name=="LANL") %>%
  dplyr::summarise(val=sum(within_95_pi!="within")/length(within_95_pi)*100)
print(paste0("Percentage of 14-step-ahead predictions outside 95% PIs for LANL across the entire time period is ", formatC(as.numeric(percentage), format="f", digits=1), "%"))

percentage = forecast_combined %>%
  dplyr::summarise(val=sum(abs(pe)<=10)/length(pe)*100)
print(paste0("Percentage of 14-step-ahead predictions outside 95% PIs for UT across the entire time period is ", formatC(as.numeric(percentage), format="f", digits=1), "%"))
