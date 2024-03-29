###############################################################################################################
# Script for downloading and compiling ground truth data from JHU, NYT, ECDC, IDPH and USAFacts
###############################################################################################################

# Set working directory
setwd(wkdir)

# JHU global data
print("Downloading ground truth global data from JHU")
download("https://github.com/CSSEGISandData/COVID-19/raw/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv", "jhu_global.csv", quiet=T)
jhu_global = read.csv("jhu_global.csv", stringsAsFactors=F, check.names=F)
unlink("jhu_global.csv", recursive=T)

# ECDC global data
print("Downloading ground truth global data from ECDC")
download("https://opendata.ecdc.europa.eu/covid19/casedistribution/csv", "ecdc_global.csv", quiet=T)
ecdc_global = read.csv("ecdc_global.csv", stringsAsFactors=F, check.names=F)
ecdc_global = ecdc_global %>%
              select(location_long=countriesAndTerritories, date=dateRep, inc.death=deaths) %>%
              dplyr::mutate(location_long=gsub("_", " ", location_long), date=as.Date(format(strptime(date, "%d/%m/%Y"), "%Y-%m-%d")))
unlink("ecdc_global.csv", recursive=T)

# JHU US states data
print("Downloading ground truth US states data from JHU")
download("https://github.com/CSSEGISandData/COVID-19/raw/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv", "jhu_us.csv", quiet=T)
jhu_us = read.csv("jhu_us.csv", stringsAsFactors=F, check.names=F)
unlink("jhu_us.csv", recursive=T)

# NYT US data
print("Downloading ground truth US data from NYT")
download("https://github.com/nytimes/covid-19-data/raw/master/us.csv", "nyt_us.csv", quiet=T)
nyt_us = read.csv("nyt_us.csv", stringsAsFactors=F, check.names=F)
unlink("nyt_us.csv", recursive=T)

# NYT US states data
print("Downloading ground truth US states data from NYT")
download("https://github.com/nytimes/covid-19-data/raw/master/us-states.csv", "nyt_us_states.csv", quiet=T)
nyt_us_states = read.csv("nyt_us_states.csv", stringsAsFactors=F, check.names=F)
unlink("nyt_us_states.csv", recursive=T)

# USAFacts data
print("Downloading ground truth US states data from USAFacts")
download("https://usafactsstatic.blob.core.windows.net/public/data/covid-19/covid_deaths_usafacts.csv", "usafacts.csv", quiet=T)
usafacts = read.csv("usafacts.csv", stringsAsFactors=F, check.names=F)
unlink("usafacts.csv", recursive=T)

# CovidTracking US data
print("Downloading ground truth US data from CovidTracking")
download("https://github.com/COVID19Tracking/covid-tracking-data/raw/master/data/us_daily.csv", "covidtracking_us.csv", quiet=T)
covidtracking_us = read.csv("covidtracking_us.csv", stringsAsFactors=F, check.names=F)
unlink("covidtracking_us.csv", recursive=T)

# CovidTracking US states data
print("Downloading ground truth US states data from CovidTracking")
download("https://github.com/COVID19Tracking/covid-tracking-data/raw/master/data/states_daily_4pm_et.csv", "covidtracking_us_states.csv", quiet=T)
covidtracking_us_states = read.csv("covidtracking_us_states.csv", stringsAsFactors=F, check.names=F)
unlink("covidtracking_us_states.csv", recursive=T)

###############################################################################################################
# Standardising country/US state name and add iso3c/state abb.
###############################################################################################################

# List name of countries in the global data and standardising name
all_countries    = unique(c(jhu_global$`Country/Region`, ecdc_global$location_long))
loc_short_global = countrycode(all_countries, origin="country.name", destination="iso3c", warn=F, nomatch=NULL)
loc_long_global  = countrycode(loc_short_global, origin="iso3c", destination="country.name", warn=F, nomatch=NULL)
loc_short_global[all_countries=="Kosovo"] = "KSV"

# List of US states and sovereign
all_us       = unique(c(jhu_us$Province_State, nyt_us_states$state))
loc_long_us  = gsub("Virgin Islands", "U.S. Virgin Islands", all_us)
loc_short_us = mapvalues(all_us, from=c(state.name, "District of Columbia", "American Samoa", "Guam", "Northern Mariana Islands", "Puerto Rico", "Virgin Islands"),
                         to=c(state.abb, "DC", "ASM", "GUM", "MNP", "PRI", "VIR"))

###############################################################################################################
# Compiling all ground truth data
###############################################################################################################
jhu_global = jhu_global %>%
             select(location_long=`Country/Region`, ends_with("/20")) %>%
             dplyr::mutate(location_long=mapvalues(location_long, from=all_countries, to=loc_long_global, warn_missing=F)) %>%
             group_by(location_long) %>%
             summarise_all(list(~sum(.))) %>%
             gather(date, cum.death, -location_long) %>%
             group_by(location_long) %>%
             dplyr::mutate(location_short=mapvalues(location_long, from=loc_long_global, to=loc_short_global, warn_missing=F), 
                           date=mdy(date), inc.death=cum.death-lag(cum.death), gt_source="JHU") %>%
             drop_na(inc.death) %>%
             as.data.frame()

jhu_us = jhu_us %>%
         select(location_long=Province_State, ends_with("/20")) %>%
         dplyr::mutate(location_long=mapvalues(location_long, from=all_us, to=loc_long_us, warn_missing=F)) %>%
         group_by(location_long) %>%
         summarise_all(list(~sum(.))) %>%
         gather(date, cum.death, -location_long) %>%
         group_by(location_long) %>%
         dplyr::mutate(location_short=mapvalues(location_long, from=loc_long_us, to=loc_short_us, warn_missing=F), 
                       date=mdy(date), inc.death=cum.death-lag(cum.death), gt_source="JHU") %>%
         drop_na(inc.death) %>%
         as.data.frame()

nyt_us = nyt_us %>%
         select(date, cum.death=deaths) %>%
         dplyr::mutate(date=as.Date(date), inc.death=cum.death-lag(cum.death), location_long="United States", location_short="USA", gt_source="NYT") %>%
         drop_na(inc.death)

nyt_us_states = nyt_us_states %>%
                select(location_long=state, date, cum.death=deaths) %>%
                dplyr::mutate(location_long=mapvalues(location_long, from=all_us, to=loc_long_us, warn_missing=F)) %>%
                group_by(location_long) %>%
                dplyr::mutate(location_short=mapvalues(location_long, from=loc_long_us, to=loc_short_us, warn_missing=F),
                              date=as.Date(date), inc.death=cum.death-lag(cum.death), gt_source="NYT") %>%
                drop_na(inc.death) %>%
                as.data.frame()

ecdc_global = ecdc_global %>%
              dplyr::mutate(location_long=mapvalues(location_long, from=all_countries, to=loc_long_global, warn_missing=F)) %>%
              group_by(location_long) %>%
              arrange(date) %>%
              dplyr::mutate(location_short=mapvalues(location_long, from=loc_long_global, to=loc_short_global, warn_missing=F), 
                            cum.death=cumsum(inc.death), gt_source="ECDC") %>%
              as.data.frame()

usafacts = usafacts %>%
           select(location_short=State, ends_with("/20")) %>%
           group_by(location_short) %>%
           summarise_all(list(~sum(.))) %>%
           gather(date, cum.death, -location_short) %>%
           group_by(location_short) %>%
           dplyr::mutate(date=mdy(date), location_long=mapvalues(location_short, from=c(state.abb, "DC"), to=c(state.name, "District of Columbia"), warn_missing=F),
                  inc.death=cum.death-lag(cum.death), gt_source="USAFacts") %>%
           drop_na(inc.death) %>%
           as.data.frame()

usafacts_us = usafacts %>%
              group_by(date, gt_source) %>%
              dplyr::summarise(inc.death=sum(inc.death), cum.death=sum(cum.death)) %>%
              as.data.frame() %>%
              dplyr::mutate(location_short="USA", location_long="United States")

covidtracking_us = covidtracking_us %>%
                   select(date, cum.death=death) %>%
                   arrange(date) %>%
                   dplyr::mutate(date=as.Date(as.character(date), format=c("%Y%m%d")), inc.death=cum.death-lag(cum.death), location_long="United States", 
                          location_short="USA", gt_source="CovidTracking") %>%
                   drop_na(inc.death)

covidtracking_us_states = covidtracking_us_states %>%
                          select(date, location_short=state, cum.death=death, inc.death=deathIncrease) %>%
                          dplyr::mutate(date=as.Date(as.character(date), format=c("%Y%m%d")), location_short=mapvalues(location_short, from=c("AS", "GU", "MP", "PR", "VI"), 
                                 to=c("ASM", "GUM", "MNP", "PRI", "VIR")), location_long=mapvalues(location_short, from=loc_short_us, to=loc_long_us, warn_missing=F), 
                                 gt_source="CovidTracking") %>%
                          drop_na(cum.death, inc.death)

idph = covidtracking_us_states %>%
       filter(location_short=="IL") %>%
       dplyr::mutate(gt_source="IDPH")

setwd(paste0(wkdir,"/JHURD"))
jhurd = read.csv("jhurd.csv", stringsAsFactors=F, check.names=F)
jhurd = jhurd %>%
        dplyr::mutate(date=as.Date(date))

gt = rbind.fill(jhu_global, jhu_us, nyt_us, nyt_us_states, ecdc_global, idph, usafacts, usafacts_us, covidtracking_us, covidtracking_us_states, jhurd) %>% select(date, location_long, location_short, gt_source, cum.death, inc.death)
setwd(wkdir)

# Save into summary folder
files_in_dir = list.files()
if(!"summary" %in% files_in_dir){
  dir.create("summary")
}
setwd(paste0(wkdir, "/summary/"))
print("Saving ground truth data from JHU, NYT, ECDC, IDPH, USAFacts and CovidTracking in summary folder")
write.csv(gt, "gt.csv", row.names=F)
setwd(wkdir)