## boosting using log difference in case counts as predictors
## Nicholas Reich
## June 2014

tic <- Sys.time()

#####################################################
## create boosted models for smoothed Bangkok data ## 
#####################################################
setwd("~/Documents/code_versioned/denguePrediction/dengueForecastAnalyses/boostingSandbox/")
require(mboost)

bkkdat <- readRDS("predData.rds")

fmla <- formula(y ~ bols(L1N1) + bols(L1N2) + bols(L1N3) + 
                        bols(L2N1) + bols(L2N2) + bols(L2N3) + 
                        bols(L3N1) + bols(L3N2) + bols(L3N3) +
                        bbs(time.in.yr, df=3, cyclic=TRUE, knots=4, boundary.knots=c(0, 26)))
                        ## bols(L1N1, L1N2, L1N3, L2N1, L2N2, L2N3, L3N1, L3N2, L3N3) 
                        ## bbs(t, knots=2, center=TRUE, df=1) 

## function to parallelize cross-validations
myApply <- function(X, FUN, ...) {
        myFun <- function(...) {
                require("mboost") # load mboost on nodes
                FUN(...)
        }
        ## further set up steps as required
        parLapply(cl = cl, X, myFun, ...)
}
cl <- makeCluster(20) # e.g. to run cvrisk on 18 nodes via PVM

#################################
## quantile regression models  ##
#################################
# MSTOP_QR <- 100000
# ctl_qr <- boost_control(mstop=MSTOP_QR, trace=TRUE)
# gam_qr_med <- gamboost(fmla, 
#                   data=bkkdat, offset=bkkdat$off, 
#                   family=QuantReg(tau=.5), control=ctl_qr)
# save.image()
# 
# gam_qr_low <- gamboost(fmla, 
#                   data=bkkdat, offset=bkkdat$off,  
#                   family=QuantReg(tau=.05), control=ctl_qr)
# save.image()
# 
# gam_qr_high <- gamboost(fmla, 
#                   data=bkkdat, offset=bkkdat$off, 
#                   family=QuantReg(tau=.95), control=ctl_qr)
# save.image()
# 
# ## cross-validate models
# cvr_qr_med <- cvrisk(gam_qr_med, papply=myApply, grid = seq(1000, MSTOP_QR, by = 1000))
# plot(cvr_qr_med)
# cvr_qr_low <- cvrisk(gam_qr_low, papply=myApply, grid = seq(1000, MSTOP_QR, by = 1000))
# plot(cvr_qr_low)
# cvr_qr_high <- cvrisk(gam_qr_high, papply=myApply, grid = seq(1000, MSTOP_QR, by = 1000))
# plot(cvr_qr_high)
# save.image()
# 
# ## make and plot predictions
# bkkdat$pred_median_qr <- predict(gam_qr_med)
# bkkdat$pred_lowci_qr <- predict(gam_qr_low)
# bkkdat$pred_highci_qr <- predict(gam_qr_high)
# save.image()
# 
# ggplot(bkkdat) + geom_line(aes(t, y)) + geom_line(aes(t, pred_median_qr), color="red") +
#         geom_ribbon(aes(x=t, ymin=pred_lowci_qr, ymax=pred_highci_qr), alpha=.3)
# 


####################
## poisson models ##
####################
MSTOP_POIS <- 1000
ctl_pois <- boost_control(mstop=MSTOP_POIS, nu=.005, trace=TRUE)
gam_pois <- gamboost(fmla, 
                  data=bkkdat, offset=bkkdat$off, 
                  family=Poisson(), control=ctl_pois)
save.image()

## cross-validate models
cvr_pois <- cvrisk(gam_pois, papply=myApply, grid = seq(100, MSTOP_POIS, by = 100))
plot(cvr_pois)
stopCluster(cl)

## make and plot predictions
bkkdat$pred_pois <- exp(predict(gam_pois))
ggplot(bkkdat) + geom_line(aes(t, y)) + geom_line(aes(t, pred_pois), color="red") 
save.image()


## plot all together
ggplot(bkkdat) + geom_line(aes(t, y)) + 
        geom_line(aes(t, pred_pois), color="red") +
        geom_line(aes(t, pred_median_qr), color="blue") +
        geom_ribbon(aes(x=t, ymin=pred_lowci_qr, ymax=pred_highci_qr), alpha=.3)

toc <- Sys.time()

(toc-tic)

