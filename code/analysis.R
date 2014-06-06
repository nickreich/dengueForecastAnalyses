## dengue forecast analyses
## Nicholas Reich
## June 2014

tic <- Sys.time()
###########################################
## local options: user/computer-specific ##
###########################################
## root_dir should be the parent directory for the dengueForecastAnalyses repository
root_dir <- '~/Documents/code_versioned/denguePrediction/'
pgsql <- "~/credentials/sql_zaraza.rds"
options(mc.cores=24)
DATA_THRU_WEEK <- 18
## end local options ##

setwd(file.path(root_dir, 'dengueForecastAnalyses'))

#######################
## pull data from DB ##
#######################

## setup data pulls, ssh connection to zaraza needs to be established
source('../dengue/shared_data.R')

## helper functions for aggregation 
source('../dengue/data_processing/stable_biweek_function.R')

## pull data and aggregate
source('../dengue/data_aggregation/counts_by_disease+province+date_sick_biweek+date_sick_year.R', echo=TRUE)

## put into wide format
source('../dengue/data_aggregation/create_standard_wide_format.R')

## run and knit predictions 
require(knitr)
pred_path <- file.path(root_dir, 
                       'dengueForecastAnalyses',
                       'predictions',
                       paste0('week', DATA_THRU_WEEK))
setwd(pred_path)
        
knit(file.path(pred_path, paste0('predictionReport_week', DATA_THRU_WEEK, '.Rnw')))

## tex it twice, for references to align
system("pdflatex predictionReport_week18.tex")
system("pdflatex predictionReport_week18.tex")

toc <- Sys.time()

(toc-tic)


