wkdir = "~/COVID-19"        ###### Change path to your working directory accordingly
if(!file.exists(wkdir)){
  dir.create(wkdir)
}
setwd(wkdir)

packages = c("RCurl", "downloader", "countrycode", "lubridate", "plyr", "dplyr", "stringr", "tidyr", "usmap")
if(!all(packages %in% rownames(installed.packages()))){
  install.packages(packages[!packages %in% rownames(installed.packages())])
}
lapply(packages, require, character.only=T)

source("data_downloader.R")
source("gt_downloader.R")
source("LANL.R")
source("Geneva.R")
source("UT.R")
source("YYG.R")
source("IHME.R")
source("reich_lab_data.R")
source("analysis.R")