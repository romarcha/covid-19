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

# IDPH Illinois data
print("Downloading ground truth Illinois state data from IDPH")
download("https://github.com/cobeylab/covid_IL/raw/master/Data/incident_idph_regions.csv", "idph.csv", quiet=T)
idph = read.csv("idph.csv", stringsAsFactors=F, check.names=F)
unlink("idph.csv", recursive=T)

# USAFacts data
print("Downloading ground truth US state data from USAFacts")
download("https://usafactsstatic.blob.core.windows.net/public/data/covid-19/covid_deaths_usafacts.csv", "usafacts.csv", quiet=T)
usafacts = read.csv("usafacts.csv", stringsAsFactors=F, check.names=F)
unlink("usafacts.csv", recursive=T)

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

idph = idph %>%
       group_by(test_date) %>%
       summarise_at(vars(deaths, inc_deaths), sum) %>%
       dplyr::mutate(test_date=as.Date(test_date), location_long="Illinois", location_short="IL", gt_source="IDPH") %>%
       rename_at(vars(test_date, deaths, inc_deaths), ~ c("date", "cum.death", "inc.death")) %>%
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

gt = rbind.fill(jhu_global, jhu_us, nyt_us, nyt_us_states, ecdc_global, idph, usafacts) %>% select(date, location_long, location_short, gt_source, cum.death, inc.death)

# Save into summary folder
files_in_dir = list.files()
if(!"summary" %in% files_in_dir){
  dir.create("summary")
}
setwd(paste0(wkdir, "/summary/"))
print("Saving ground truth data from JHU, NYT, ECDC, IDPH and USAFacts in summary folder")
write.csv(gt, "gt.csv", row.names=F)
setwd(wkdir)