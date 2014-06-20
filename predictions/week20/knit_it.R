## dengue forecast analyses
## Nicholas Reich
## June 2014

tic <- Sys.time()
DATA_THRU_WEEK <- 20

require(knitr)

## set up paths and filenames
pred_path <- file.path('~/Documents/code_versioned/denguePrediction/', 
                       'dengueForecastAnalyses',
                       'predictions',
                       paste0('week', DATA_THRU_WEEK))
setwd(pred_path)
knitr_file_path <- file.path(pred_path, paste0('predictionReport_week', DATA_THRU_WEEK))

## knit it
knit(paste0(knitr_file_path, '.Rnw'))

## tex it twice, for references to align
system(paste0("pdflatex ", knitr_file_path, ".tex"))
system(paste0("pdflatex ", knitr_file_path, ".tex"))


toc <- Sys.time()

(toc-tic)


