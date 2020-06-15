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
# 17. ISUandPKU
# 18. SWC
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
setwd(wkdir)

# Name of folder for storing prediction data from each model
folder = c("Auquan",
           "COVIDhub",
           rep("CU",10),
           "CovidActNow",
           "GA_Tech",
           rep("Geneva",3),
           "IHME",
           rep("Imperial",2),
           "IowaStateLW",
           "JHU",
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
           "UA",
           "ISUandPKU",
           "SWC")

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
          "CU-nochange",
          "CovidActNow",
          "GA_Tech",
          "Geneva",
          "Geneva",
          "Geneva_states",
          "IHME",
          "Imperial1",
          "Imperial2",
          "IowaStateLW",
          "JHU_IDD",
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
          "UA",
          "ISUandPKU",
          "SWC")

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
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/CU-nochange/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/CovidActNow-SEIR_CAN/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/GT-DeepCOVID/",
              "https://renkulab.io/gitlab/covid-19/covid-19-forecast/raw/master/outputs/predictions_deaths_",
              "https://renkulab.io/gitlab/covid-19/covid-19-forecast/raw/master/outputs/JHU_deaths_predictions_",
              "https://renkulab.io/gitlab/covid-19/covid-19-forecast/raw/master/outputs/JHU_US_deaths_predictions_",
              "https://ihmecovid19storage.blob.core.windows.net/archive/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/Imperial-ensemble1/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/Imperial-ensemble2/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/IowaStateLW-STEM/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/JHU_IDD-CovidSP/",
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
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/UA-EpiCovDA/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/ISUandPKU-vSEIdR/",
              "https://github.com/reichlab/covid19-forecast-hub/raw/master/data-processed/SWC-TerminusCM/")

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
                  "-CU-nochange.csv",
                  "-CovidActNow-SEIR_CAN.csv",
                  "-GT-DeepCOVID.csv",
                  ".csv",
                  ".csv",
                  ".csv",
                  "/ihme-covid19.zip",
                  "-Imperial-ensemble1.csv",
                  "-Imperial-ensemble2.csv",
                  "-IowaStateLW-STEM.csv",
                  "-JHU_IDD-CovidSP.csv",
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
                  "-UA-EpiCovDA.csv",
                  "-ISUandPKU-vSEIdR.csv",
                  "-SWC-TerminusCM.csv")

# First reported date for each model
today = Sys.Date()
dates = as.Date(c("2020-05-04", # Auquan
             "2020-04-13", # Covidhub
             "2020-04-12", # CU-60contact
             "2020-04-12", # CU-70contact
             "2020-04-12", # CU-80contact
             "2020-05-03", # CU-80contact1x10p
             "2020-05-07", # CU-80contact1x5p
             "2020-05-03", # CU-80contactw10p
             "2020-05-07", # CU-80contactw5p
             "2020-04-12", # CU-nointerv
             "2020-05-10", # CU-select
             "2020-05-31", # CU-nochange
             "2020-05-09", # CovidActNow
             "2020-05-04", # GA_Tech
             "2020-04-15", # Geneva
             "2020-05-19", # Geneva
             "2020-05-19", # Geneva
             "2020-03-25", # IHME
             "2020-03-15", # Imperial1
             "2020-03-15", # Imperial2
             "2020-04-26", # IowaStateLW
             "2020-04-24", # JHU_IDD
             "2020-04-05", # LANL_states_cum
             "2020-04-05", # LANL_states_cum
             "2020-04-15", # LANL_states_inc
             "2020-04-15", # LANL_states_inc
             "2020-04-26", # LANL_global_cum
             "2020-04-26", # LANL_global_inc
             "2020-04-22", # MIT
             "2020-04-13", # MOBS
             "2020-04-27", # NotreDame
             "2020-05-01", # UCLA
             "2020-05-05", # UChicago40
             "2020-05-05", # UChicago60
             "2020-05-05", # UChicago80
             "2020-05-05", # UChicago100
             "2020-05-18", # UChicago10increase
             "2020-05-18", # UChicago30increase
             "2020-04-13", # UMass_Exp
             "2020-04-26", # UMass_MB
             "2020-04-14", # UT_states
             "2020-04-14", # UT_US
             "2020-04-01", # YYG_states
             "2020-04-02", # YYG_global
             "2020-05-18", # ERDC
             "2020-05-08", # Quantori
             "2020-05-18", # PSI
             "2020-05-17", # UA
             "2020-05-25", # ISUandPKU
             "2020-05-25")) # SWC

for (i in 1:length(model)){
  
  # List all folders/files in working directory
  files_in_dir = list.files()
  
  # Create a new folder for each model
  if(!folder[i] %in% files_in_dir){
    dir.create(folder[i])
  }
  setwd(paste0(wkdir, "/", folder[i]))
  
  # Check for missing data in the folder
  files_in_model_dir = list.files(pattern = paste0("^", model[i], "(.*)csv$"))
  last_date          = if(length(files_in_model_dir)!=0) max(as.Date(str_extract(files_in_model_dir, "[0-2]{4}[-][0-9]{2}[-][0-9]{2}"))) else dates[i]-1
  if(model_url[i]!="https://renkulab.io/gitlab/covid-19/covid-19-forecast/raw/master/outputs/predictions_deaths_"){
    missing_dates = seq(last_date+1, today, by="days")
  }else if(last_date>=as.Date("2020-05-17")){
    next
  }else{
    missing_dates = seq(last_date-1, as.Date("2020-05-17"), by="days")
  }
  
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