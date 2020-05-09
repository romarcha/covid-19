rm(list = ls())

# Installing required packages
packages = c("countrycode", "downloader", "dplyr", "plyr")
install.packages(packages)
lapply(packages, require, character.only = T)

# Path to working directory
wkdir = "~/Code/covid-19"

# Name of model and set working directory
model = "LANL_global_inc"
setwd(paste0(wkdir, "/", model))

# Ground truth source
gt_source = "JHU"

# Load all csv files in the model folder and combine all data
csv_file      = list.files(pattern=model)
prediction    = do.call(rbind, lapply(1:length(csv_file), function(i) read.csv(csv_file[i])))
prediction    = prediction[as.Date(prediction$dates) > as.Date(prediction$fcst_date),]
names(prediction)[names(prediction) == "countries"] = "country"
prediction$dates = as.Date(prediction$dates)

# Download latest JHU ground truth data
download("https://github.com/CSSEGISandData/COVID-19/raw/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv",
         "jhu_truth.csv")
jhu_truth = read.csv("jhu_truth.csv")
jhu_truth = aggregate(.~Country.Region, jhu_truth, sum)

cum_death = jhu_truth[,5:ncol(jhu_truth)]
inc_death = apply(cum_death, 1, diff)
jhu_truth = data.frame(country=rep(jhu_truth$Country.Region, each=nrow(inc_death)), 
                       dates=rep(seq(as.Date("2020-01-23"), as.Date("2020-01-23") + nrow(inc_death) - 1, by="days"), ncol(inc_death)),
                       incident.death=as.vector(inc_death))

# Rows where there is no matching
no_match  = anti_join(prediction, jhu_truth, by=c("dates", "country"))
all_match = merge(prediction, jhu_truth, by.x=c("dates", "country"), by.y=c("dates", "country"), all=F)
all_merge = rbind.fill(all_match, no_match)

# Location short. Manually adding Kosovo
location_short = countrycode(all_merge$country, origin ="country.name", destination="iso3c")
location_short[all_merge$country=="Kosovo"] = "KSV"
location_long = countrycode(location_short, origin="iso3c", destination="country.name")
location_long[is.na(location_long)] = "Kosovo"

# Calculating various measure
error            = all_merge$incident.death - all_merge$q.50
pe               = error/all_merge$incident.death * 100
adj_pe           = error/(all_merge$incident.death + all_merge$q.50) * 100
pe[all_merge$q.50==0 & all_merge$incident.death==0] = 0
adj_pe[all_merge$q.50==0 & all_merge$incident.death==0] = 0
pe[all_merge$q.50!=0 & all_merge$incident.death==0] = Inf

ape              = abs(pe)
adj_ape          = abs(adj_pe)
logistic_ape     = 1 / (1 + exp(-ape/100))
logistic_adj_ape = 1 / (1 + exp(-adj_ape/100))

above = all_merge$incident.death > all_merge$q.975
below = all_merge$incident.death < all_merge$q.025

within_95_pi                                  = rep("inside", nrow(all_merge))
within_95_pi[is.na(all_merge$incident.death)] = NA
within_95_pi[which(above==T)]                 = "above"
within_95_pi[which(below==T)]                 = "below"

outside_95p_by                                  = rep(0, nrow(all_merge))
outside_95p_by[is.na(all_merge$incident.death)] = NA
outside_95p_by[which(above==T)]                 = all_merge$incident.death[which(above==T)] - 
                                                  all_merge$q.975[which(above==T)]
outside_95p_by[which(below==T)]                 = all_merge$incident.death[which(below==T)] - 
                                                  all_merge$q.025[which(below==T)]

df = data.frame(target_date      = all_merge$dates, 
                forecast_date    = all_merge$fcst_date, 
                lookahead        = difftime(as.Date(all_merge$dates), as.Date(all_merge$fcst_date), units="days"),
                model_name       = model,
                location_long    = location_long,
                location_short   = location_short,
                prediction_type  = "full_perc",
                expected_value   = all_merge$q.50,
                perc_0.010       = all_merge$q.01,
                perc_0.025       = all_merge$q.025,
                perc_0.050       = all_merge$q.05,
                perc_0.100       = all_merge$q.10,
                perc_0.150       = all_merge$q.15,
                perc_0.200       = all_merge$q.20,
                perc_0.250       = all_merge$q.25,
                perc_0.300       = all_merge$q.30,
                perc_0.350       = all_merge$q.35,
                perc_0.400       = all_merge$q.40,
                perc_0.450       = all_merge$q.45,
                perc_0.500       = all_merge$q.50,
                perc_0.550       = all_merge$q.55,
                perc_0.600       = all_merge$q.60,
                perc_0.650       = all_merge$q.65,
                perc_0.700       = all_merge$q.70,
                perc_0.750       = all_merge$q.75,
                perc_0.800       = all_merge$q.80,
                perc_0.850       = all_merge$q.85,
                perc_0.900       = all_merge$q.90,
                perc_0.950       = all_merge$q.95,
                perc_0.975       = all_merge$q.975,
                perc_0.990       = all_merge$q.99,
                gt_source        = gt_source,
                gt_jhu           = all_merge$incident.death,
                gt_nyt           = NA,
                gt_ecdc          = NA,
                error            = error,
                pe               = pe,
                adj_pe           = adj_pe,
                ape              = ape,
                adj_ape          = adj_ape,
                logistic_ape     = logistic_ape,
                logistic_adj_ape = logistic_adj_ape,
                within_95_pi     = within_95_pi,
                outside_95p_by   = outside_95p_by
)

setwd(wkdir)

files_in_dir = list.files()
if("summary" %in% files_in_dir == F){
  dir.create("summary")
}
setwd(paste0(wkdir, "/summary/"))

write.csv(df, paste0(model, "-summary.csv"), row.names = F)
setwd(paste0(wkdir))
