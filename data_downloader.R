###############################################################################################################
# Script for downloading COVID-19 prediction data
###############################################################################################################
###############################################################################################################
#
# Data from Reich Lab Github page (https://github.com/reichlab/covid19-forecast-hub/tree/master/data-processed):
# 1. Auquan
# 2. COVIDhub
# 3. CU
# 4. CovidActNow
# 5. GA_Tech
# 6. Imperial
# 7. IowaStateLW
# 8. JHU
# 9. MIT
# 10. MOBS
# 11. UCLA
# 12. UMass
# 13. ERDC
# 14. Quantori
# 15. PSI
# 16. UA
#
# Data from respective modellers:
# 1. Geneva
# 2. IHME
# 3. LANL
# 4. NotreDame
# 5. UChicago
# 6. UT
# 7. YYG
#
# First reported date of predictions for each model updated on 17 May 2020.
###############################################################################################################

# Set time zone as AEDT
Sys.setenv(TZ="Australia/Sydney")

# Set working directory
wkdir = getwd()

# Name of folder for storing prediction data from each model
folder = c("Auquan",
           "COVIDhub",
           rep("CU",9),
           "CovidActNow",
           "GA_Tech",
           "Geneva",
           "IHME",
           rep(c("Imperial", "IowaStateLW"), each=2),
           rep("JHU",3),
           rep("LANL",6),
           "MIT",
           "MOBS",
           "NotreDame",
           "UCLA",
           rep("UChicago",6),
           rep(c("UMass", "UT", "YYG"), each=2),
           "ERDC",
           "Quantori",
           "PSI",
           "UA")

# Name of prediction model (separated by global and US states)
model = c("Auquan",
          "COVIDhub",
          "CU-60contact",
          "CU-70contact",
          "CU-80contact",
          "CU-80contact1x10p",
          "CU-80contact1x5p",
          "CU-80contactw10p",
          "CU-80contactw5p",
          "CU-nointerv",
          "CU-select",
          "CovidActNow",
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
          "LANL_states_cum",
          "LANL_states_cum",
          "LANL_states_inc",
          "LANL_states_inc",
          "LANL_global_cum",
          "LANL_global_inc",
          "MIT",
          "MOBS",
          "NotreDame",
          "UCLA",
          "UChicago40",
          "UChicago60",
          "UChicago80",
          "UChicago100",
          "UChicago10increase",
          "UChicago30increase",
          "UMass_Exp",
          "UMass_MB",
          "UT_states",
          "UT_US",
          "YYG_states",
          "YYG_global",
          "ERDC",
          "Quantori",
          "PSI",
          "UA")

# Link to download page
model_url = c("https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/Auquan-SEIR/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/COVIDhub-ensemble/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/CU-60contact/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/CU-70contact/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/CU-80contact/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/CU-80contact1x10p/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/CU-80contact1x5p/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/CU-80contactw10p/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/CU-80contactw5p/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/CU-nointerv/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/CU-select/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/CovidActNow-SEIR_CAN/",
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
              "https://github.com/cobeylab/covid_IL/raw/master/Forecasting/forecast_hub_projections/",
              "https://github.com/cobeylab/covid_IL/raw/master/Forecasting/forecast_hub_projections/",
              "https://github.com/cobeylab/covid_IL/raw/master/Forecasting/forecast_hub_projections/",
              "https://github.com/cobeylab/covid_IL/raw/master/Forecasting/forecast_hub_projections/",
              "https://github.com/cobeylab/covid_IL/raw/master/Forecasting/forecast_hub_projections/",
              "https://github.com/cobeylab/covid_IL/raw/master/Forecasting/forecast_hub_projections/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/UMass-ExpertCrowd/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/UMass-MechBayes/",
              "https://github.com/UT-Covid/USmortality/raw/master/forecasts/archive/UT-COVID19-states-forecast-",
              "https://github.com/UT-Covid/USmortality/raw/master/forecasts/archive/UT-COVID19-usa-forecast-",
              "https://github.com/youyanggu/covid19_projections/raw/master/projections/combined/",
              "https://github.com/youyanggu/covid19_projections/raw/master/projections/combined/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/USACE-ERDC_SEIR/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/Quantori-Multiagents/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/PSI-DRAFT/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/UA-EpiCovDA/")

# File naming convention adopted
file_name_web = c("-Auquan-SEIR.csv",
                  "-COVIDhub-ensemble.csv",
                  "-CU-60contact.csv",
                  "-CU-70contact.csv",
                  "-CU-80contact.csv",
                  "-CU-80contact1x10p.csv",
                  "-CU-80contact1x5p.csv",
                  "-CU-80contactw10p.csv",
                  "-CU-80contactw5p.csv",
                  "-CU-nointerv.csv",
                  "-CU-select.csv",
                  "-CovidActNow-SEIR_CAN.csv",
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
                  "-UChicago-CovidIL_10_increase.csv",
                  "-UChicago-CovidIL_30_increase.csv",
                  "-UMass-ExpertCrowd.csv",
                  "-UMass-MechBayes.csv",
                  ".csv",
                  ".csv",
                  "_us.csv",
                  "_global.csv",
                  "-USACE-ERDC_SEIR.csv",
                  "-Quantori-Multiagents.csv",
                  "-PSI-DRAFT.csv",
                  "-UA-EpiCovDA.csv")

# List containing dates from first reported date until today for each model
today = Sys.Date()
dates = list(seq(as.Date("2020-05-04"), today, by="days"), # Auquan
             seq(as.Date("2020-04-13"), today, by="days"), # Covidhub
             seq(as.Date("2020-04-12"), today, by="days"), # CU-60contact
             seq(as.Date("2020-04-12"), today, by="days"), # CU-70contact
             seq(as.Date("2020-04-12"), today, by="days"), # CU-80contact
             seq(as.Date("2020-05-03"), today, by="days"), # CU-80contact1x10p
             seq(as.Date("2020-05-07"), today, by="days"), # CU-80contact1x5p
             seq(as.Date("2020-05-03"), today, by="days"), # CU-80contactw10p
             seq(as.Date("2020-05-07"), today, by="days"), # CU-80contactw5p
             seq(as.Date("2020-04-12"), today, by="days"), # CU-nointerv
             seq(as.Date("2020-05-10"), today, by="days"), # CU-select
             seq(as.Date("2020-05-09"), today, by="days"), # CovidActNow
             seq(as.Date("2020-05-04"), today, by="days"), # GA_Tech
             seq(as.Date("2020-04-15"), today, by="days"), # Geneva
             seq(as.Date("2020-03-25"), today, by="days"), # IHME
             seq(as.Date("2020-03-15"), today, by="days"), # Imperial1
             seq(as.Date("2020-03-15"), today, by="days"), # Imperial2
             seq(as.Date("2020-04-26"), today, by="days"), # IowaStateLW10
             seq(as.Date("2020-04-26"), today, by="days"), # IowaStateLW15
             seq(as.Date("2020-04-24"), today, by="days"), # JHU_IDD
             seq(as.Date("2020-05-03"), today, by="days"), # JHU_IDD_High
             seq(as.Date("2020-05-03"), today, by="days"), # JHU_IDD_Mod
             seq(as.Date("2020-04-05"), today, by="days"), # LANL_states_cum
             seq(as.Date("2020-04-05"), today, by="days"), # LANL_states_cum
             seq(as.Date("2020-04-15"), today, by="days"), # LANL_states_inc
             seq(as.Date("2020-04-15"), today, by="days"), # LANL_states_inc
             seq(as.Date("2020-04-26"), today, by="days"), # LANL_global_cum
             seq(as.Date("2020-04-26"), today, by="days"), # LANL_global_inc
             seq(as.Date("2020-04-22"), today, by="days"), # MIT
             seq(as.Date("2020-04-13"), today, by="days"), # MOBS
             seq(as.Date("2020-04-27"), today, by="days"), # NotreDame
             seq(as.Date("2020-05-01"), today, by="days"), # UCLA
             seq(as.Date("2020-05-05"), today, by="days"), # UChicago40
             seq(as.Date("2020-05-05"), today, by="days"), # UChicago60
             seq(as.Date("2020-05-05"), today, by="days"), # UChicago80
             seq(as.Date("2020-05-05"), today, by="days"), # UChicago100
             seq(as.Date("2020-05-18"), today, by="days"), # UChicago10increase
             seq(as.Date("2020-05-18"), today, by="days"), # UChicago30increase
             seq(as.Date("2020-04-13"), today, by="days"), # UMass_Exp
             seq(as.Date("2020-04-26"), today, by="days"), # UMass_MB
             seq(as.Date("2020-04-14"), today, by="days"), # UT_states
             seq(as.Date("2020-04-14"), today, by="days"), # UT_US
             seq(as.Date("2020-04-01"), today, by="days"), # YYG_states
             seq(as.Date("2020-04-02"), today, by="days"), # YYG_global
             seq(as.Date("2020-05-18"), today, by="days"), # ERDC
             seq(as.Date("2020-05-08"), today, by="days"), # Quantori
             seq(as.Date("2020-05-18"), today, by="days"), # PSI
             seq(as.Date("2020-05-17"), today, by="days")) # UA

for (i in 1:length(model)){
  
  # List all folders/files in working directory
  files_in_dir = list.files()
  
  # Create a new folder for each model
  if(!folder[i] %in% files_in_dir){
    dir.create(folder[i])
  }
  setwd(paste0(wkdir, "/", folder[i]))
  
  # Check for missing data in the folder
  if (model[i]=="IHME"){
    # Manually adding 2020-04-02 as link to download page exists but has the same data as 2020-04-01!
    files_in_model_dir = c(list.files(pattern = ".csv"), "IHME-2020-04-02.csv")
  }else{
    files_in_model_dir = list.files(pattern = ".csv")
  }
  files_in_model_dir = sub("*.csv","",files_in_model_dir)
  missing_dates      = sub(paste0(model[i], "."), "", setdiff(paste0(model[i], "-", dates[[i]]), files_in_model_dir))
  
  for(j in 1:length(missing_dates)){
    
    # Full url to each dataset for each model (NOTE: LANL has a slightly different url convention)
    if(grepl("LANL", model[i])){
      model_url_by_date = paste0(model_url[i], missing_dates[j], "/deaths/", missing_dates[j], file_name_web[i])
    }else{
      model_url_by_date = paste0(model_url[i], missing_dates[j], file_name_web[i])
    }
    
    # If the url exists, then download the data
    # Naming of data: model name followed by reporting date
    if(url.exists(model_url_by_date)){
      print(paste0("Downloading data for model ", model[i], " for the reporting date ", missing_dates[j]))
      
      if(model[i]=="IHME"){
        filename = paste0(model[i], "-", missing_dates[j], ".zip")
        download(model_url_by_date, filename, mode="wb", quiet=T)
        
        # Unzipping file, move file to current directory and delete folder
        unzip(filename)
        zip_dir = list.dirs('.', recursive=FALSE)
        if(j==1){
          ihme_csv_file = list.files(zip_dir, pattern=".csv")
        }else{
          ihme_csv_file = list.files(zip_dir, pattern="*pital*")
        }
        pathfrom = paste0(zip_dir, "/", ihme_csv_file)
        file.rename(from=pathfrom, to=paste0(getwd(), "/", folder[i], "-", missing_dates[j], ".csv"))
        unlink(c(zip_dir, filename), recursive=T)
      }else{
        filename = paste0(model[i], "-", missing_dates[j], ".csv")
        download(model_url_by_date, filename, mode="wb", quiet=T) 
      }
    }
  }
  setwd(wkdir)
}