## master file for running forecasts of dengue in Thailand
## Nicholas Reich
## July 2014

#######################
## SET LOCAL OPTIONS ## 
#######################

## modeling globals
DATA_THRU_WEEK <- 26
MODEL <- 'spamd_tops3_lag1'
DATE_DATA_RECEIVED <- as.Date('2014-07-10')

## define machine-specific properties/folders
CORES <- 20 
root_dir <- '~/Documents/code_versioned/denguePrediction/' ## parent dir for dengueForecastAnalyses repo
spamd_dir <- '~/Documents/code_versioned/spamd/'
pgsql <- '~/credentials/sql_zaraza.rds'

#######################
## USE LOCAL OPTIONS ## 
#######################

## set number of computing cores
options(mc.cores=CORES)

## main repo
setwd(file.path(root_dir, 'dengueForecastAnalyses'))
gh_repo_hash <- system("git rev-parse HEAD | cut -c1-10", intern=TRUE)

## folder with thai administrative data
peripheral_data_dir <- '../dengue_data/peripheral_data/'

## folder where data will be stored
aggregated_data_dir <- file.path(root_dir, 
                                 'dengueForecastAnalyses',
                                 'data') 

## load packages
library(lubridate)
library(parallel)
library(RPostgreSQL)
require(reshape2)
require(dplyr)
library(integrator) ## install_github('sakrejda/data-integrator/package_dir')
library(cruftery)   ## install_github('sakrejda/cruftery/package_dir')

## helper functions for aggregation ## NOT NEEDED WITH cruftery?
## source('../dengue/data_processing/stable_biweek_function.R')


#######################
## pull data from DB ##
#######################

## setup data pulls, ssh connection to zaraza needs to be established
link <- db_connector(pgsql)

## pull data and aggregate, must be connected to zaraza
source('../dengue/data_aggregation/counts_by_disease+province+date_sick_biweek+date_sick_year.R')

## put into wide format, save all objects needed for prediction to aggregated_data
source('code/create_standard_wide_format.R')

## get dengue repo version
setwd('../dengue/')
dengue_repo_hash <- system("git rev-parse HEAD | cut -c1-10", intern=TRUE)


####################################
## source the spamd modeling code ##
####################################

setwd(spamd_dir)
spamd_version <- system('svn info |grep Revision: |cut -c11-', intern=TRUE)
source("trunk/source/dengpred/R/Utility.r")
source.deng.pred("trunk/source/dengpred/R/")
source("trunk/manuscripts/realTimeForecasting/code/spatialPlotting.R")
## load(file.path(aggregated_data_dir, fname)) ## only needed if starting from this point

#############################
## find, set province info ##
#############################

load("trunk/manuscripts/realTimeForecasting/predictions/THA_adm1.RData")
prov_data <- read.csv("trunk/manuscripts/realTimeForecasting/predictions/thaiProvinces.csv")

## define locations for which forecasts will be created
pnames <- as.character(province_names)

## merging Nong Khai and Bueng Kan
idx_NK <- which(pnames=="Nong Khai")
idx_BK <- which(pnames=="Bueng Kan")

count_matrix[idx_BK,][is.na(count_matrix[idx_BK,])] <- 0

count_matrix[idx_NK,] <- count_matrix[idx_NK,] + count_matrix[idx_BK,]
count_matrix <- count_matrix[-idx_BK,]
fips <- fips[-idx_BK]
pnames <- pnames[-idx_BK]
pop <- pop[-idx_BK]


##############################
## create a den.data object ##
##############################

## matching FIPS into the spatial data frame
gadm@data$FIPS_ADMIN <- as.character(fips[match(gadm@data$NAME_1, pnames)])
dat <- new.cntry.data(case.counts = count_matrix,
                      time.info = time_matrix,
                      fips = fips,
                      names = pnames,
                      pop.data = pop,
                      loc.info = gadm)


################################
## subset and smooth the data ##
################################
cutoff_date <- 2014 + (DATA_THRU_WEEK-8)/52 ## starting 8 weeks ago
den_sub  <- subset(dat, t.criteria=dat@t<cutoff_date)
den_smooth <- smooth.cdata(den_sub)


###################
## run forecasts ##
###################

## chosen 3 tops and lag 1 based on plots of MASE across all provinces from 
##    casePredictionStepsFwd.R
##    predictionPerformance_09132013a.rda
den_mdl <- fit.cntry.pred.mdl(den_smooth, num.tops=3, cor.lags=1)

den_forecast <- forecast(den_mdl, den_smooth, steps=6, stochastic=T, verbose=T, 
                         MC.sims=1000, predictions.only=T, num.cores=18)

########################
## save forecast data ##
########################

## move forecast data to long format
forecast_data <- den_forecast@.Data
colnames(forecast_data) <- paste(den_forecast@yr, formatC(den_forecast@time.in.yr, width=2, flag="0"))
forecast_data <- data.frame(forecast_data)
forecast_data$pid <- den_forecast@loc.info@data$FIPS_ADMIN
forecast_data$pname <- rownames(forecast_data)
forecast_data$numid <- 1:(den_forecast@n.locs)
forecasts <- tbl_df(melt(forecast_data, id.vars = c("pid", "pname", "numid")))

## add prediction intervals
forecasts$lb <- forecasts$ub <- NA

for (i in 1:(den_forecast@n.locs)){
        idx <- which(forecasts$numid == i)
        forecasts[idx,c("lb", "ub")] <- predint(den_forecast, i, 0.95)
}

## add dates, round counts, drop unneeded columns
forecasts <- 
        forecasts %>% 
        mutate(biweek = as.numeric(substr(variable, 7, 8)),
               year = as.numeric(substr(variable, 2, 5)),
               count = round(value),
               model = MODEL,
               rpt_year = year(Sys.time()),
               rpt_biweek = date_to_biweek(Sys.Date()),
               rpt_date = Sys.Date(),
               recd_date = DATE_DATA_RECEIVED,
               gh_repo = "dengueForecastAnalyses",
               gh_version = gh_repo_hash,
               spamd_version = spamd_version,
               dengue_version = dengue_repo_hash) %>%
        select(-variable, -value)

## get outbreak probabilities
outbreak_prob <- tbl_df(data.frame(get.outbreak.probability(den_forecast, den_smooth)))
colnames(outbreak_prob) <- paste(den_forecast@yr, formatC(den_forecast@time.in.yr, width=2, flag="0"))
outbreak_prob <- outbreak_prob %>% mutate(pid=den_forecast@loc.info@data$FIPS_ADMIN)
melted_outbreak_prob <- tbl_df(melt(outbreak_prob, id.vars = c("pid")))
melted_outbreak_prob <- 
        melted_outbreak_prob %>%
        mutate(biweek = as.numeric(substr(variable, 7, 8)),
               year = as.numeric(substr(variable, 2, 5)),
               outbreak.prob = value) %>%
        select(-variable, -value)

## join forecasts and outbreak probabilities
forecasts <- left_join(forecasts, melted_outbreak_prob)

## save the forecasts
forecast_file <- paste0(format(Sys.Date(), "%Y%m%d"), 
                        '_forecast_week', 
                        DATA_THROUGH_WEEK, 
                        '.csv'))

write.csv(forecasts, file=file.path(root_dir, 
                                    'dengueForecastAnalyses',
                                    'forecasts',
                                    forecast_file)
                 
#########################
## generate the report ##
#########################
