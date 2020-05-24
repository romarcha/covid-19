# Change working directory to be the one of this file.
setwd(dirname(parent.frame(2)$ofile))

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