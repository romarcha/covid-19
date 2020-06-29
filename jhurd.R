# Set working directory
setwd(wkdir)

files_in_dir = list.files()

if(!"JHURD" %in% files_in_dir){
  dir.create("JHURD")
}
setwd(paste0(wkdir, "/JHURD"))

files_in_dir    = list.files()
date_downloaded = str_extract(files_in_dir, "[0-2]{4}[-][0-9]{2}[-][0-9]{2}")
last_date       = max(date_downloaded[!is.na(date_downloaded)])
dates           = seq(as.Date(last_date)+1, Sys.Date(), by="days")
file_dates      = format(dates, "%m-%d-%y")

if(length(dates)>0){
  for(i in 1:length(dates)){
    
    url = paste0("https://github.com/CSSEGISandData/COVID-19/raw/master/csse_covid_19_data/csse_covid_19_daily_reports/", file_dates[i], "20.csv")
    
    if(url.exists(url)){
      download.file(url, paste0(dates[i], ".csv"), quiet=T)
    }
  }
}

files_in_dir = list.files()

summary = lapply(list.files(pattern="^[0-2]{4}[-][0-9]{2}[-][0-9]{2}(.*)csv$"), function(i) read.csv(i, stringsAsFactors=F, check.names=T))
date    = as.Date(rep(str_extract(list.files(pattern="^[0-2]{4}[-][0-9]{2}[-][0-9]{2}(.*)csv$"), "[0-2]{4}[-][0-9]{2}[-][0-9]{2}"), unlist(lapply(summary, nrow))))
summary = cbind(date=date, do.call(rbind.fill, summary))

summary = summary %>%
          dplyr::mutate(Province.State=if_else(is.na(Province.State), Province_State, Province.State),
                        Country.Region=if_else(is.na(Country.Region), Country_Region, Country.Region),
                        Province.State=if_else(Province.State=="Virgin Islands" & Country.Region=="US", "US Virgin Islands", Province.State),
                        Country.Region=if_else(Country.Region=="US", Province.State, Country.Region),
                        location_short=if_else(Province.State %in% c(state.name, "District of Columbia"), mapvalues(Province.State, from=c(state.name, "District of Columbia"), to=c(state.abb, "DC"), warn_missing=F),
                                               if_else(Country.Region=="Kosovo", "KSV", countrycode(Country.Region, origin="country.name", destination="iso3c", warn=F))),
                        location_long=if_else(nchar(location_short)==2, mapvalues(location_short, from=c(state.abb, "DC"), to=c(state.name, "District of Columbia"), warn_missing=F),
                                              if_else(location_short=="KSV", "Kosovo", countrycode(location_short, origin="iso3c", destination="country.name", warn=F)))) %>%
          tidyr::drop_na(location_short) %>%
          select(date, Province.State, Country.Region, Deaths, starts_with("location")) %>%
          group_by(date, location_short, location_long) %>%
          dplyr::summarise(cum.death=sum(Deaths)) %>%
          as.data.frame() %>%
          group_by(location_short, location_long) %>%
          dplyr::mutate(inc.death=cum.death-lag(cum.death), gt_source="JHURD") %>%
          as.data.frame() %>%
          tidyr::drop_na(inc.death) %>%
          filter(location_short!="USA")

us_total = summary %>%
           filter(nchar(location_short)==2) %>%
           group_by(date) %>%
           dplyr::summarise(inc.death=sum(inc.death), cum.death=sum(cum.death)) %>%
           as.data.frame() %>%
           dplyr::mutate(gt_source="JHURD", location_short="USA", location_long="United States")

write.csv(rbind.fill(summary, us_total), "jhurd.csv", row.names=F)
setwd(wkdir)