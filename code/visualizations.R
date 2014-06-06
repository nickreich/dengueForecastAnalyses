############################
## visualize/analyze data ##
############################

## can be run after 
# source('../dengue/data_aggregation/counts_by_disease+province+date_sick_biweek+date_sick_year.R', echo=TRUE)

require(plyr)
dat <- subset(counts_by_disease_province_biweek_year, disease==26)
dat$not_missing <- !is.na(dat$count)

ggplot(data=dat, aes(x=date_sick_year+date_sick_biweek/26, y=province, fill=log(count+1))) + geom_raster()
ggplot(data=dat, aes(x=date_sick_year+date_sick_biweek/26, y=province, fill=not_missing)) + geom_raster()

ggplot(data=dat, aes(x=date_sick_year+date_sick_biweek/26, y=province, fill=log(count+1))) + geom_raster() + xlim(2013.7, 2014.5)