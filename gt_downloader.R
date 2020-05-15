###############################################################################################################
# Script for downloading and standardising ground truth data from JHU, NYT and ECDC
###############################################################################################################

rm(list=ls())

# Set working directory
setwd("~/Code/covid-19")

# Installing required packages
packages = c("dplyr", "downloader", "countrycode", "lubridate", "tidyr")
install.packages(packages)
lapply(packages, require, character.only=T)

# JHU global data
print("Downloading ground truth global data from JHU")
download("https://github.com/CSSEGISandData/COVID-19/raw/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv", "jhu_global.csv", quiet=T)
jhu_global = read.csv("jhu_global.csv", stringsAsFactors=F, check.names=F)
unlink("jhu_global.csv", recursive=T)
jhu_global = jhu_global %>%
             select(location_name=`Country/Region`, ends_with("/20")) %>%
             group_by(location_name) %>%
             summarise_all(list(~sum(.))) %>%
             gather(date, cum.death, -location_name) %>%
             group_by(location_name) %>%
             mutate(date=mdy(date), inc.death=cum.death-lag(cum.death), gt_source="JHU") %>%
             drop_na(inc.death) %>%
             as.data.frame()
print("Writing standardised ground truth global data from JHU")
write.csv(jhu_global, "jhu_global.csv", row.names=F)


# JHU US states data
print("Downloading ground truth US states data from JHU")
download("https://github.com/CSSEGISandData/COVID-19/raw/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv", "jhu_us.csv", quiet=T)
jhu_us = read.csv("jhu_us.csv", stringsAsFactors=F, check.names=F)
unlink("jhu_us.csv", recursive=T)
jhu_us = jhu_us %>%
         select(location_name=Province_State, ends_with("/20")) %>%
         group_by(location_name) %>%
         summarise_all(list(~sum(.))) %>%
         gather(date, cum.death, -location_name) %>%
         group_by(location_name) %>%
         mutate(date=mdy(date), inc.death=cum.death-lag(cum.death), gt_source="JHU") %>%
         drop_na(inc.death) %>%
         as.data.frame()
print("Writing standardised ground truth US states data from JHU")
write.csv(jhu_us, "jhu_us.csv", row.names=F)

                   
# NYT US data
print("Downloading ground truth US data from NYT")
download("https://github.com/nytimes/covid-19-data/raw/master/us.csv", "nyt_us.csv", quiet=T)
nyt_us = read.csv("nyt_us.csv", stringsAsFactors=F, check.names=F)
unlink("nyt_us.csv", recursive=T)
nyt_us = nyt_us %>%
         select(date, cum.death=deaths) %>%
         mutate(inc.death=cum.death-lag(cum.death), location_name="US", gt_source="NYT") %>%
         drop_na(inc.death)

# NYT US states data
print("Downloading ground truth US states data from NYT")
download("https://github.com/nytimes/covid-19-data/raw/master/us-states.csv", "nyt_us_states.csv", quiet=T)
nyt_us_states = read.csv("nyt_us_states.csv", stringsAsFactors=F, check.names=F)
unlink("nyt_us_states.csv", recursive=T)
nyt_us = nyt_us_states %>%
         select(location_name=state, date, cum.death=deaths) %>%
         group_by(location_name) %>%
         mutate(date=as.Date(date), inc.death=cum.death-lag(cum.death), gt_source="NYT") %>%
         drop_na(inc.death) %>%
         as.data.frame() %>%
         rbind(., nyt_us)
print("Writing standardised ground truth US states data from NYT")
write.csv(nyt_us, "nyt_us.csv", row.names=F)


# ECDC global data
print("Downloading ground truth global data from ECDC")
download("https://opendata.ecdc.europa.eu/covid19/casedistribution/csv", "ecdc_global.csv", quiet=T)
ecdc_global = read.csv("ecdc_global.csv", stringsAsFactors=F, check.names=F)
unlink("ecdc_global.csv", recursive=T)
ecdc_global = ecdc_global %>%
              select(location_name=countriesAndTerritories, date=dateRep, inc.death=deaths) %>%
              mutate(location_name=gsub("_", " ", location_name), date=as.Date(format(strptime(date, "%d/%m/%Y"), "%Y-%m-%d"))) %>%
              group_by(location_name) %>%
              arrange(date) %>%
              mutate(cum.death=cumsum(inc.death), gt_source="ECDC") %>%
              as.data.frame()
print("Writing standardised ground truth global data from ECDC")
write.csv(ecdc_global, "ecdc_global.csv", row.names=F)