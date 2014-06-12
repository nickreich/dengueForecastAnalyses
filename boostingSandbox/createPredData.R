## create data for dengue prediction model

## setup and run models using existing dengue analysis structure
CURRENT_WEEK <- 18
require(ggplot2)
require(reshape2)
setwd("~/Documents/code_versioned/spamd/")
source("trunk/source/dengpred/R/Utility.r")
source.deng.pred("trunk/source/dengpred/R/")
source("trunk/manuscripts/realTimeForecasting/code/spatialPlotting.R")
load('~/Documents/code_versioned/denguePrediction/dengue_data/aggregated_data/standard_wide_format/counts_through_week_18.RData')
load("trunk/manuscripts/realTimeForecasting/predictions/THA_adm1.RData")
prov_data <- read.csv("trunk/manuscripts/realTimeForecasting/predictions/thaiProvinces.csv")

## making a cntry.data object
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

## matching FIPS into the spatial data frame
gadm@data$FIPS_ADMIN <- as.character(fips[match(gadm@data$NAME_1, pnames)])

dat <- new.cntry.data(case.counts = count_matrix,
                      time.info = time_matrix,
                      fips = fips,
                      names = pnames,
                      pop.data = pop,
                      loc.info = gadm)

cutoff_date <- 2014 + (CURRENT_WEEK-8)/52 ## starting 8 weeks ago
den_sub  <- subset(dat, t.criteria=dat@t<cutoff_date)
den_smooth <- smooth.cdata(den_sub)
den_mdl <- fit.cntry.pred.mdl(den_smooth, num.tops=3, cor.lags=1:3)

saveRDS(den_mdl@loc.mdls[[1]]@data, file="predData.rds")

