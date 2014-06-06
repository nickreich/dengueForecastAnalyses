
## local options
pgsql <- "~/credentials/sql_zaraza.rds"
root_dir <- '~/Documents/code_versioned/denguePrediction/'
options(mc.cores=24)
## end local options

## setup data pulls
source('shared_data.R')

## helper functions for aggregation 
source('data_processing/stable_biweek_function.R')

## pull data and aggregate
source('data_aggregation/counts_by_disease+province+date_sick_biweek+date_sick_year.R')


