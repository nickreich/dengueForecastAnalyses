## script to create standard wide format data for forecasting
## Nicholas Reich
## June 2014

require(reshape2)

## subset to include only DHF
dhf_counts_by_province_biweek_year <- subset(counts, disease==26)

## make wide format of data
cols_to_keep <- c("province", "date_sick_biweek", "date_sick_year", "count")
dhf_counts_melt <- melt(dhf_counts_by_province_biweek_year[,cols_to_keep], 
                   id.vars=c('province','date_sick_year','date_sick_biweek'))
standard_count_format <- dcast(data=dhf_counts_melt, formula=province ~ date_sick_year + date_sick_biweek )
standard_count_format <- standard_count_format[
        order(standard_count_format[['province']]),]

## load in census data for population and province info
census <- read.csv(file.path(peripheral_data_dir,'2010Census.csv'), header=TRUE, skip=1)
colnames(census) <-
        c('names','HASC','code','FIPS','region','pop.2000','area_km','area_miles')

census <- census[order(census$code),c('names','code','FIPS','pop.2000')]
if (!all(census$ISO == standard_count_format$province)) 
        stop("Not all provinces appear in the census.")

counts <- cbind(census,standard_count_format)
counts[['province']] <- NULL

## For rows
split_time <- strsplit(x=colnames(counts)[5:ncol(counts)], split='_')
year <- sapply(split_time, function(x) as.numeric(x[1]))
biweek <- sapply(split_time, function(x) as.numeric(x[2]))
time <- year + biweek/26

## For colanmes
biweek_string <- formatC(x=biweek, width=2, flag="0")
year_string <- sapply(year, function(x) substr(x=as.character(x),start=3,stop=4))
colnames(counts) <- c(colnames(counts)[1:4],paste0('BW',biweek_string,'.',year_string))
rownames(counts) <- counts$code

# Vectors: code, fips, pop.2000
province_names <- as.character(counts[['names']])
code <- counts[['code']]
fips <- counts[['FIPS']]
pop  <- counts[['pop.2000']]

# Matrix: counts
count_matrix <- as.matrix(counts[,5:ncol(counts)])

# Matrix: 'year','time.in.year','time'
time_matrix <- as.matrix(data.frame(year=year, time.in.year=biweek, time=time))

fname <- paste0("counts_through_week_", DATA_THRU_WEEK, ".RData")
save(province_names, code, fips, pop, count_matrix, time_matrix,
     file=file.path(aggregated_data_dir, fname))




