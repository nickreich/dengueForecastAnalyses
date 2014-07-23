dengueForecastAnalyses
======================

Code for running forecasts of dengue fever outbreaks in Thailand.

The vision for the structure of this directory is that there would be subdirectories called code, data, reports, and forecasts. Also in the main directory, there would be a file called makeForecasts.R. Within that script, there is a single variable that is set, indicating up through what week you want forecasts run for.

That script would then create forecasts (for now, based on "spamd"-style general additive models with seasonality and lag terms from top correlated provinces). Forecasts would be generated and dumped in a standardized format into the forecasts folder. Reports would also be generated (if desired) for collaborators.

Some of the modeling code from the spamd SVN repository will live in this repository, with a specific version number saved for inclusion in the forecasts. 

The makeForecast.R file would complete the following sequence of operations
* set local options for file dependencies, number of computing cores, etc...
* read data from the zaraza database
* source the spamd modeling code
* read in spatial info about Thailand
* define locations for which forecasts will be created
* create a den.data object
* run a smooth on the data, then the forecast, using built-in spamd functions
* generate the report

Each forecast txt file will have a table with the following columns present:
* pname: province name
* pid: provice FIPS id
* year: year of forecast 
* biweek: biweek of forecast
* count: count (the forecast itself)
* lb: lower bound of 95% prediction interval for forecast count
* ub: upper bound of 95% prediction interval for forecast count
* outbreak_prob: Predicted probability of an outbreak
* model: a title for the model used to create the forecasts
* rpt_year: year of the date the forecast was generated
* rpt_biweek: biweek of the date the forecast was generated
* rpt_date: the date the forecast was generated
* recd_date: the date the data was received
* spamd_version: hash of the svn version for the spamd code used
* gh_version: hash of the github version for the dengueForecastAnalyses code used
* gh_repo: name of the github repository used to generate the predictions
* dengue_version: hash of the dengue git repo on zaraza used

[NB: to save git last commit, you can run the R command `system("git rev-parse HEAD | cut -c1-10", intern=TRUE)` to retrieve the first 10 digits of the current commit hash into an R character value.]

* change rpt\_date to analysis\_date
* change recd\_date to delivery\_date
* add to and from dates 
* move db_connector() function to cruftery
* add two columns for each repo (repo1\_name and repo1\_hash)
