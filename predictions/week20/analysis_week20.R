## dengue forecast analyses
## Nicholas Reich
## June 2014

tic <- Sys.time()

## All libraries used in the scripts.
library(lubridate)
library(parallel)
library(RPostgreSQL)
library(integrator)

###########################################
## local options: user/computer-specific ##
###########################################
## root_dir should be the parent directory for the dengueForecastAnalyses repository
root_dir <- '~/Documents/code_versioned/denguePrediction/'
pgsql <- "~/credentials/sql_zaraza.rds"
options(mc.cores=24)
DATA_THRU_WEEK <- 20

## set up other file paths
setwd(file.path(root_dir, 'dengueForecastAnalyses'))
peripheral_data_dir <- '../dengue_data/peripheral_data/'
aggregated_data_dir <- '../dengue_data/aggregated_data/standard_wide_format/'
        
#######################
## pull data from DB ##
#######################

## setup data pulls, ssh connection to zaraza needs to be established
link <- db_connector(pgsql)

## helper functions for aggregation 
source('../dengue/data_processing/stable_biweek_function.R')

## pull data and aggregate
source('../dengue/data_aggregation/counts_by_disease+province+date_sick_biweek+date_sick_year.R', echo=TRUE)

## put into wide format
source('code/create_standard_wide_format.R')

## run and knit predictions 
require(knitr)
pred_path <- file.path(root_dir, 
                       'dengueForecastAnalyses',
                       'predictions',
                       paste0('week', DATA_THRU_WEEK))
setwd(pred_path)
        
knitr_file_path <- file.path(pred_path, paste0('predictionReport_week', DATA_THRU_WEEK))
knit(paste0(knitr_file_path, '.Rnw'))

## tex it twice, for references to align
system(paste0("pdflatex ", knitr_file_path, ".tex"))
system(paste0("pdflatex ", knitr_file_path, ".tex"))

toc <- Sys.time()

(toc-tic)


