###############################################################################################################
# Auquan      - Data for: US national and states.
#               Note: Data from Reich Lab Github page.
#
# COVIDhub    - Data for: US national and states.
#               Note: Data from Reich Lab Github page.
#
# CU          - Data for: US national and states.
#               Note: Data from Reich Lab Github page. 6 different models available. See original repository: 
#               https://github.com/shaman-lab/COVID-19Projection
#
# GA_Tech     - Data for: US national and states.
#               Note: Data from Reich Lab Github page.
#
# Geneva      - Data for: Global.
#
# ????IHME
#
# Imperial    - Data for: US national.
#               Note: Data from Reich Lab Github page. 2 different models available.
#
# IowaStateLW - Data for: US national and states. 
#               Note: Data from Reich Lab Github page. 2 different models available. Will consider scrapping from 
#               https://covid19.stat.iastate.edu in future.
#
# JHU         - Data for: US national
#               Note: Data from Reich Lab Github page. 3 different models available.
#
# LANL        - Data for: Global and US states.
#
# MIT         - Data for: US states
#               Note: Data from Reich Lab Github page. Will consider scrapping from 
#               https://www.covidanalytics.io/projections in future.
#
# MOBS        - Data for: US national and states. 
#               Note: Data from Reich Lab Github page. Will consider scrapping from 
#               https://covid19.gleamproject.org in future.
#
# NotreDame   - Data for: Illinois, Indiana, Kentucky, Michigan, Minnesota, Ohio, Wisconsin
#
# UChicago    - Data for: Illinois.
#               Note: Data from Reich Lab Github page. 4 different models available.
#
# UCLA        - Data for: US national and states.
#               Note: Data from Reich Lab Github page. Will consider scrapping from 
#               https://covid19.uclaml.org in future.
#
# UMass_Exp   - Data for: US national.
#               Note: Data from Reich Lab Github page.
#
# UMass_MB    - Data for: US national and states.
#               Note: Data from Reich Lab Github page.
#
# UT          - Data for: US national and states.
#
# YYG         - Data for: Global and US states.
#
# First result reported date for each model updated on 8 May 2020.
###############################################################################################################

# Path to working directory
wkdir = "~/Code/covid-19"

# Name of model, separated by global and US states for LANL, UT and YYG
model = c("Auquan",
          "COVIDhub",
          "CU-60",
          "CU-70",
          "CU-80",
          "CU-80_1x",
          "CU-80w",
          "CU-no",
          "GA_Tech",
          "Geneva",
          "IHME",
          "Imperial1",
          "Imperial2",
          "IowaStateLW10",
          "IowaStateLW15",
          "JHU_IDD",
          "JHU_IDD_High",
          "JHU_IDD_Mod",
          "LANL (States cum)",
          "LANL (States cum)",
          "LANL (States inc)",
          "LANL (States inc)",
          "LANL (Global cum)",
          "LANL (Glocal inc)",
          "MIT",
          "MOBS",
          "NotreDame",
          "UCLA",
          "UChicago40",
          "UChicago60",
          "UChicago80",
          "UChicago100",
          "UMass_Exp",
          "UMass_MB",
          "UT (States)",
          "UT (US)",
          "YYG (States)",
          "YYG (Global)")

# Link to download page
model_url = c("https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/Auquan-SEIR/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/COVIDhub-ensemble/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/CU-60contact/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/CU-70contact/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/CU-80contact/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/CU-80contact_1x/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/CU-80contactw/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/CU-nointerv/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/GT-DeepCOVID/",
              "https://renkulab.io/gitlab/covid-19/covid-19-forecast/raw/master/outputs/predictions_deaths_",
              "https://ihmecovid19storage.blob.core.windows.net/archive/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/Imperial-ensemble1/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/Imperial-ensemble2/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/IowaStateLW-STEM10/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/IowaStateLW-STEM15/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/JHU_IDD-CovidSP/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/JHU_IDD-CovidSPHighDist/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/JHU_IDD-CovidSPModDist/",
              "https://covid-19.bsvgateway.org/forecast/us/files/",
              "https://covid-19.bsvgateway.org/forecast/us/files/",
              "https://covid-19.bsvgateway.org/forecast/us/files/",
              "https://covid-19.bsvgateway.org/forecast/us/files/",
              "https://covid-19.bsvgateway.org/forecast/global/files/",
              "https://covid-19.bsvgateway.org/forecast/global/files/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/MIT_CovidAnalytics-DELPHI/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/MOBS_NEU-GLEAM_COVID/",
              "https://github.com/confunguido/covid19_ND_forecasting/raw/master/output/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/UCLA-SuEIR/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/UChicago-CovidIL_40/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/UChicago-CovidIL_60/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/UChicago-CovidIL_80/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/UChicago-CovidIL_100/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/UMass-ExpertCrowd/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/UMass-MechBayes/",
              "https://github.com/UT-Covid/USmortality/raw/master/forecasts/archive/UT-COVID19-states-forecast-",
              "https://github.com/UT-Covid/USmortality/raw/master/forecasts/archive/UT-COVID19-usa-forecast-",
              "https://github.com/youyanggu/covid19_projections/raw/master/reich_forecasts/",
              "https://github.com/youyanggu/covid19_projections/raw/master/projections/combined/")

# File naming convention adopted
file_name_web = c("-Auquan-SEIR.csv",
                  "-COVIDhub-ensemble.csv",
                  "-CU-60contact.csv",
                  "-CU-70contact.csv",
                  "-CU-80contact.csv",
                  "-CU-80contact_1x.csv",
                  "-CU-80contactw.csv",
                  "-CU-nointerv.csv",
                  "-GT-DeepCOVID.csv",
                  ".csv",
                  "/ihme-covid19.zip",
                  "-Imperial-ensemble1.csv",
                  "-Imperial-ensemble2.csv",
                  "-IowaStateLW-STEM10.csv",
                  "-IowaStateLW-STEM15.csv",
                  "-JHU_IDD-CovidSP.csv",
                  "-JHU_IDD-CovidSPHighDist.csv",
                  "-JHU_IDD-CovidSPModDist.csv",
                  "_deaths_quantiles_us.csv",
                  "_deaths_quantiles_us_website.csv",
                  "_deaths_incidence_quantiles_us.csv",
                  "_deaths_incidence_quantiles_us_website.csv",
                  "_deaths_quantiles_global_website.csv",
                  "_deaths_incidence_quantiles_global_website.csv",
                  "-MIT_CovidAnalytics-DELPHI.csv",
                  "-MOBS_NEU-GLEAM_COVID.csv",
                  "-NotreDame-FRED.csv",
                  "-UCLA-SuEIR.csv",
                  "-UChicago-CovidIL_40.csv",
                  "-UChicago-CovidIL_60.csv",
                  "-UChicago-CovidIL_80.csv",
                  "-UChicago-CovidIL_100.csv",
                  "-UMass-ExpertCrowd.csv",
                  "-UMass-MechBayes.csv",
                  ".csv",
                  ".csv",
                  "-YYG-ParamSearch.csv",
                  "_global.csv")

# List containing dates from first reported date until today for each model
today = Sys.Date()
dates = list(seq(as.Date("2020-05-04"), today, by="days"),
             seq(as.Date("2020-04-13"), today, by="days"),
             seq(as.Date("2020-04-12"), today, by="days"),
             seq(as.Date("2020-04-12"), today, by="days"),
             seq(as.Date("2020-04-12"), today, by="days"),
             seq(as.Date("2020-05-03"), today, by="days"),
             seq(as.Date("2020-05-03"), today, by="days"),
             seq(as.Date("2020-04-12"), today, by="days"),
             seq(as.Date("2020-05-04"), today, by="days"),
             seq(as.Date("2020-04-15"), today, by="days"),
             seq(as.Date("2020-03-25"), today, by="days"),
             seq(as.Date("2020-03-15"), today, by="days"),
             seq(as.Date("2020-03-15"), today, by="days"),
             seq(as.Date("2020-04-26"), today, by="days"),
             seq(as.Date("2020-04-26"), today, by="days"),
             seq(as.Date("2020-04-24"), today, by="days"),
             seq(as.Date("2020-05-03"), today, by="days"),
             seq(as.Date("2020-05-03"), today, by="days"),
             seq(as.Date("2020-04-05"), today, by="days"),
             seq(as.Date("2020-04-05"), today, by="days"),
             seq(as.Date("2020-04-15"), today, by="days"),
             seq(as.Date("2020-04-15"), today, by="days"),
             seq(as.Date("2020-04-26"), today, by="days"),
             seq(as.Date("2020-04-26"), today, by="days"),
             seq(as.Date("2020-04-22"), today, by="days"),
             seq(as.Date("2020-04-13"), today, by="days"),
             seq(as.Date("2020-04-27"), today, by="days"),
             seq(as.Date("2020-05-01"), today, by="days"),
             seq(as.Date("2020-05-05"), today, by="days"),
             seq(as.Date("2020-05-05"), today, by="days"),
             seq(as.Date("2020-05-05"), today, by="days"),
             seq(as.Date("2020-05-05"), today, by="days"),
             seq(as.Date("2020-04-13"), today, by="days"),
             seq(as.Date("2020-04-26"), today, by="days"),
             seq(as.Date("2020-04-14"), today, by="days"),
             seq(as.Date("2020-04-14"), today, by="days"),
             seq(as.Date("2020-04-13"), today, by="days"),
             seq(as.Date("2020-04-13"), today, by="days"))

# Set working directory
setwd(wkdir)


for (i in 1:length(model)){
  
  # List all folders in current working directory
  files_in_dir = list.files()
  
  # Create a new folder for each model to store data
  if(model[i] %in% files_in_dir == F){
    dir.create(model[i])
  }
  setwd(paste0(wkdir, "/", model[i]))
  
  # Check for missing data in the folder
  if (model[i]=="IHME"){
    # Manually adding 2020-04-02 as link to download page exists but has the same data as 2020-04-01!
    files_in_model_dir = c(list.files(pattern = ".zip"), "IHME-2020-04-02.zip")
  }else{
    files_in_model_dir = list.files(pattern = ".csv")
  }
  files_in_model_dir = substring(files_in_model_dir, 1, nchar(files_in_model_dir) - 4)
  missing_files      = setdiff(paste0(model[i], "-", dates[[i]]), files_in_model_dir)
  missing_dates      = substring(missing_files, nchar(missing_files[1])-9)
  
  for(j in 1:length(missing_dates)){
    
    # Full url to each dataset for each model (NOTE: LANL has a slightly different url convention)
    if(substring(model[i], 1, 4)=="LANL"){
      model_url_by_date = paste0(model_url[i], missing_dates[j], "/deaths/", missing_dates[j], file_name_web[i])
    }else{
      model_url_by_date = paste0(model_url[i], missing_dates[j], file_name_web[i])
    }
    
    # If the url exists, then download the data
    # Naming of data: model name followed by forecast date
    if (url.exists(model_url_by_date)){
      print(paste0("Downloading data for model ", model[i], " for the forecast date ", missing_dates[j]))
      
      if (model[i]=="IHME"){
        filename = paste0(model[i], "-", missing_dates[j], ".zip")
        download(model_url_by_date, filename, mode="wb", quiet=T)
        
        # Unzipping file, move file to current directory and delete folder
        unzip(filename)
        zip_dir = list.dirs('.', recursive=FALSE)
        if (j==1){
          ihme_csv_file = list.files(zip_dir, pattern=".csv")
        }else{
          ihme_csv_file = list.files(zip_dir, pattern="*pital*")
        }
        pathfrom = paste0(zip_dir, "/", ihme_csv_file)
        file.rename(from=pathfrom, to=paste0(getwd(), "/", model[i], "-", missing_dates[j], ".csv"))
        unlink(zip_dir, recursive=T)
      }else{
        filename = paste0(model[i], "-", missing_dates[j], ".csv")
        download(model_url_by_date, filename, mode="wb", quiet=T) 
      }
    }
  }
  setwd(wkdir)
}
