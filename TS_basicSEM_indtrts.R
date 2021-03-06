###############################################
# sensitivity analysis of long-term data sets #
# using basic model in 'TS_alternatemodels.R' #
# *using individual traits*                   #
# for each combination of                     #
# phylogenetic and functional                 #
# diversity metric:                           #
# 1) FDis + eMNTD                             #
# 2) FRic + eMNTD                             #
# 3) FDis + eMPD                              #
# 4) FRic + eMPD                              #
###############################################

require(dplyr)
require(piecewiseSEM)
library(semPlot)
library(lmerTest)
library(nlme)
library(car) 

# Data
stab<-read.delim("data.csv",sep=",",header=T)

stab<-filter(stab,Site!="BIODEPTH_GR")  # should get rid of site where we didn't have good trait coverage

stab_4<-select(stab,Site,Study_length,UniqueID,SppN,eMPD,eMNTD,ePSE,sMPD,sMNTD,FDis4,FRic4,PCAdim1_4trts,SLA, LDMC, LeafN, LeafP,
               Plot_TempStab,Plot_Biomassxbar, Plot_Biomasssd,Gross_synchrony, 
               mArid,sdAridity)

# for plots with ONLY 1 spp, we assume that a species #is perfectly synchronized with itself

stab_4$Plot_Asynchrony<-ifelse(is.na(stab_4$Plot_Asynchrony)==TRUE,1,stab_4$Plot_Asynchrony) 
stab_4$Gross_synchrony<-ifelse(is.na(stab_4$Gross_synchrony)==TRUE,1,stab_4$Gross_synchrony) 
stab_4$Loreau_synchrony<-ifelse(is.na(stab_4$Loreau_synchrony)==TRUE,1,stab_4$Loreau_synchrony) 

# convert synchrony metrics to different scale

stab_4$PlotAsynchrony_s<-stab_4$Plot_Asynchrony*-1

stab_4$GrossAsynchrony_s<-stab_4$Gross_synchrony*-1

# further adjustments

stab_4$SppN<-as.numeric(stab_4$SppN)

stab_4$TS_lg2<-log(stab_4$Plot_TempStab,base=2)

stab_4$lg2SppN <- log(stab_4$SppN,2)

stab_4$lg2_mArid  <-log(stab_4$mArid,base=2)

# Filter out NAs for Asynchrony and  FRic4

stab_4<-filter(stab_4, is.na(PlotAsynchrony_s)==FALSE)
stab_444<-filter(stab_4, is.na(FRic4)==FALSE)

# Filter out NAs for all functional traits

stab_555<-filter(stab_444, is.na(LDMC)==FALSE)
stab_555<-filter(stab_555, is.na(LeafN)==FALSE)
stab_555<-filter(stab_555, is.na(LeafP)==FALSE)

# Control list set up for LMM in nlme 

bb<-lmeControl(msMaxIter=0,msVerbose = TRUE,opt="optim",maxIter=100,optimMEthod="L-BFGS-B")  ######## "msMaxIter=0" is important in here!!!
cc<-lmeControl(opt="optim")

#######################
#  test individual  ###
# functional traits ###
#######################

#######################
# SLA #################
#######################

##################
# FDis_eMNTD #####
##################

modList2=list(
  lme(eMNTD~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(FDis4~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(GrossAsynchrony_s~lg2SppN+FDis4+eMNTD+sdAridity+lg2_mArid,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(TS_lg2~GrossAsynchrony_s+eMNTD+FDis4+SLA+lg2SppN+sdAridity+lg2_mArid,random=~1+lg2SppN|Site,
      control=cc,data=stab_555)
)


lapply(modList2, plot)

# Explore distribution of residuals

lapply(modList2, function(i) hist(resid(i)))

# Look at variance inflation factors
lapply(modList2[3:4], vif)

sem.fit(modList2,stab_555,corr.errors=c("eMNTD~~FDis4"),conditional=T,
        model.control = list(lmeControl(opt = "optim"))) #naive model

emntdfdis.fit<-sem.fit(modList2,stab_555,corr.errors=c("eMNTD~~FDis4","eMNTD ~~ SLA"),conditional=T,
                       model.control = list(lmeControl(opt = "optim")))  

emntdfdis.fit<-cbind(emntdfdis.fit$Fisher.C,emntdfdis.fit$AIC)
emntdfdis.fit$ModClass<-"FDis_eMNTD_SLA"

ts_emntd2<-sem.coefs(modList2,stab_555,standardize="scale",corr.errors=c("eMNTD~~FDis4","eMNTD ~~ SLA"))
ts_emntd2$ModClass<-"FDis_eMNTD_SLA"

mf_ts_emntd<-sem.model.fits(modList2)
mf_ts_emntd$ResponseVars<-c("eMNTD","FDis4","Asynchrony","Temp_Stability")
mf_ts_emntd$PredVars<-c("lg2SppN","lg2SppN","lg2SppN,eMNTD,FDis4, lg2_mArid, sdAridity","eMNTD,FDis4,Asynchrony,lg2SppN, SLA, lg2_mArid, sdAridity")
mf_ts_emntd$ModClass<-"FDis_eMNTD_SLA"

# write model results
write.table(ts_emntd2,"TS_emntd_fdis_sem_coefs_SIMPLE_SLA.csv",sep=",",row.names=F)
write.table(mf_ts_emntd,"TS_emntd_fdis_model_fits_SIMPLE_SLA.csv",sep=",",row.names=F)
write.table(emntdfdis.fit,"TS_emntd_fdis_semfit_SIMPLE_SLA.csv",sep=",",row.names=F)

#######################
## FRic4 - eMNTD    ###
#######################

modList22=list(
  lme(eMNTD~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(FRic4~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(GrossAsynchrony_s~lg2SppN+FRic4+eMNTD+sdAridity+lg2_mArid,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(TS_lg2~GrossAsynchrony_s+SLA+lg2SppN+eMNTD+FRic4+sdAridity+lg2_mArid,random=~1+lg2SppN|Site, control=cc,data=stab_555)
)

lapply(modList22, plot)

# Explore distribution of residuals

lapply(modList22, function(i) hist(resid(i)))

# Look at variance inflation factors
lapply(modList22[3:4], vif)

sem.fit(modList22,stab_555,corr.errors=c("eMNTD~~FRic4"),conditional=T,
        model.control = list(lmeControl(opt = "optim"))) #naive model

emntdfric.fit<-sem.fit(modList22,stab_555,corr.errors=c("FRic4~~eMNTD","eMNTD ~~ SLA"),conditional=T,
                       model.control = list(lmeControl(opt = "optim")))  # add eMNTD as predictor of TS

emntdfric.fit<-cbind(emntdfric.fit$Fisher.C,emntdfric.fit$AIC)
emntdfric.fit$ModClass<-"FRic_eMNTD_SLA"

ts_emntd2<-sem.coefs(modList22,stab_555,standardize="scale",corr.errors=c("FRic4~~eMNTD","eMNTD ~~ SLA"))
ts_emntd2$ModClass<-"FRic_eMNTD_SLA"

mf_ts_emntd<-sem.model.fits(modList22)
mf_ts_emntd$ResponseVars<-c("eMNTD","FRic4","Asynchrony","Temp_Stability")
mf_ts_emntd$PredVars<-c("lg2SppN","lg2SppN","lg2SppN,eMNTD,FRic4,lg2_mArid,sdAridity","Asynchrony,eMNTD,FRic,SLA, lg2SppN,lg2_mArid,sdAridity")
mf_ts_emntd$ModClass<-"FRic_eMNTD_SLA"

# write out model results
write.table(ts_emntd2,"TS_emntd_fric_sem_coefs_SIMPLE_SLA.csv",sep=",",row.names=F)
write.table(mf_ts_emntd,"TS_emntd_fric_model_fits_SIMPLE_SLA.csv",sep=",",row.names=F)
write.table(emntdfric.fit,"TS_emntd_fric_semfit_SIMPLE_SLA.csv",sep=",",row.names=F)

##################
# FDis_eMPD ######
##################

modList3=list(
  lme(eMPD~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(FDis4~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(GrossAsynchrony_s~lg2SppN+FDis4+eMPD+sdAridity+lg2_mArid,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(TS_lg2~GrossAsynchrony_s+SLA+lg2SppN+FDis4+eMPD+sdAridity+lg2_mArid,random=~1+lg2SppN|Site, control=cc,data=stab_555)
)


lapply(modList3, plot)

# Explore distribution of residuals

lapply(modList3, function(i) hist(resid(i)))

# Look at variance inflation factors
lapply(modList3[3:4], vif)


sem.fit(modList3,stab_555,corr.errors=c("eMPD~~FDis4"),conditional=T,
        model.control = list(lmeControl(opt = "optim"))) #naive model

empdfdis.fit<-sem.fit(modList3,stab_555,corr.errors=c("eMPD~~FDis4","eMPD ~~ SLA"),conditional=T,
                      model.control = list(lmeControl(opt = "optim")))  # 

empdfdis.fit<-cbind(empdfdis.fit$Fisher.C,empdfdis.fit$AIC)
empdfdis.fit$ModClass<-"FDis_eMPD_SLA"

ts_empd2<-sem.coefs(modList3,stab_555,standardize="scale",corr.errors=c("eMPD~~FDis4","eMPD ~~ SLA"))
ts_empd2$ModClass<-"FDis_eMPD_SLA"


mf_ts_empd<-sem.model.fits(modList3)
mf_ts_empd$ResponseVars<-c("eMPD","FDis4","Asynchrony","Temp_Stability")
mf_ts_empd$PredVars<-c("lg2SppN","lg2SppN","lg2SppN,eMPD,FDis4,lg2_mArid,sdAridity","Asynchrony,lg2SppN,SLA, lg2_mArid,sdAridity")
mf_ts_empd$ModClass<-"FDis_eMPD_SLA"

# write out model results
write.table(ts_empd2,"TS_empd_fdis_sem_coefs_SIMPLE_SLA.csv",sep=",",row.names=F)
write.table(mf_ts_empd,"TS_empd_fdis_model_fits_SIMPLE_SLA.csv",sep=",",row.names=F)
write.table(empdfdis.fit,"TS_empd_fdis_semfit_SIMPLE_SLA.csv",sep=",",row.names=F)

#######################
## FRic - eMPD #######
#######################

modList33=list(
  lme(eMPD~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(FRic4~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(GrossAsynchrony_s~lg2SppN+FRic4+eMPD+sdAridity+lg2_mArid,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(TS_lg2~GrossAsynchrony_s+SLA+lg2SppN+FRic4+eMPD+sdAridity+lg2_mArid,random=~1+lg2SppN|Site, control=cc,data=stab_555)
)

lapply(modList33, plot)

# Explore distribution of residuals

lapply(modList33, function(i) hist(resid(i)))

# Look at variance inflation factors
lapply(modList33[3:4], vif)


sem.fit(modList33,stab_555,corr.errors=c("eMPD~~FRic4"),conditional=T,
        model.control = list(lmeControl(opt = "optim"))) #naive model

smpdfdis.fit<-sem.fit(modList33,stab_555,corr.errors=c("eMPD~~FRic4","eMPD ~~ SLA"),conditional=T,
                      model.control = list(lmeControl(opt = "optim")))  

smpdfdis.fit<-cbind(smpdfdis.fit$Fisher.C,smpdfdis.fit$AIC)
smpdfdis.fit$ModClass<-"FRic4_eMPD_SLA"

ts_smpd2<-sem.coefs(modList33,stab_555,standardize="scale",corr.errors=c("eMPD~~FRic4","eMPD ~~ SLA"))
ts_smpd2$ModClass<-"FRic4_eMPD_SLA"

mf_ts_smpd<-sem.model.fits(modList33)
mf_ts_smpd$ResponseVars<-c("eMPD","FRic4","Asynchrony","Temp_Stability")
mf_ts_smpd$PredVars<-c("lg2SppN","lg2SppN","lg2SppN,eMPD,FRic4,lg2_mArid,sdAridity","Asynchrony,SLA,lg2SppN,lg2_mArid,sdAridity")
mf_ts_smpd$ModClass<-"FRic4_eMPD_SLA"

# write out model results
write.table(ts_smpd2,"TS_empd_fric_sem_coefs_SIMPLE_SLA.csv",sep=",",row.names=F)
write.table(mf_ts_smpd,"TS_empd_fric_model_fits_SIMPLE_SLA.csv",sep=",",row.names=F)
write.table(smpdfdis.fit,"TS_empd_fric_semfit_SIMPLE_SLA.csv",sep=",",row.names=F)

#######################
# LDMC ################
#######################

##################
# FDis_eMNTD #####
##################

bb<-lmeControl(msMaxIter=0,msVerbose = TRUE,opt="optim",maxIter=100,optimMEthod="L-BFGS-B")  ######## "msMaxIter=0" is important in here!!!
cc<-lmeControl(opt="optim")

modList2=list(
  lme(eMNTD~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(FDis4~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(GrossAsynchrony_s~lg2SppN+FDis4+eMNTD+sdAridity + lg2_mArid,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(TS_lg2~GrossAsynchrony_s+FDis4+eMNTD+LDMC+lg2SppN+sdAridity + lg2_mArid,random=~1+lg2SppN|Site, control=cc,data=stab_555)
)

lapply(modList2, plot)

# Explore distribution of residuals

lapply(modList2, function(i) hist(resid(i)))

# Look at variance inflation factors
lapply(modList2[3:4], vif)

sem.fit(modList2,stab_555,corr.errors=c("eMNTD~~FDis4"),conditional=T,
        model.control = list(lmeControl(opt = "optim"))) #naive model

emntdfdis.fit<-sem.fit(modList2,stab_555,corr.errors=c("eMNTD~~FDis4","eMNTD ~~ LDMC","FDis4 ~~ LDMC"),conditional=T,
                       model.control = list(lmeControl(opt = "optim")))  

emntdfdis.fit<-cbind(emntdfdis.fit$Fisher.C,emntdfdis.fit$AIC)
emntdfdis.fit$ModClass<-"FDis_eMNTD_LDMC"

ts_emntd2<-sem.coefs(modList2,stab_555,standardize="scale",corr.errors=c("eMNTD~~FDis4","eMNTD ~~ LDMC","FDis4 ~~ LDMC"))
ts_emntd2$ModClass<-"FDis_eMNTD_LDMC"

mf_ts_emntd<-sem.model.fits(modList2)
mf_ts_emntd$ResponseVars<-c("eMNTD","FDis4","Asynchrony","Temp_Stability")
mf_ts_emntd$PredVars<-c("lg2SppN","lg2SppN","lg2SppN,eMNTD,FDis4, lg2_mArid,sdAridity","eMNTD,Asynchrony,lg2SppN, LDMC, lg2_mArid,sdAridity")
mf_ts_emntd$ModClass<-"FDis_eMNTD_LDMC"

# write out model results
write.table(ts_emntd2,"TS_emntd_fdis_sem_coefs_SIMPLE_LDMC.csv",sep=",",row.names=F)
write.table(mf_ts_emntd,"TS_emntd_fdis_model_fits_SIMPLE_LDMC.csv",sep=",",row.names=F)
write.table(emntdfdis.fit,"TS_emntd_fdis_semfit_SIMPLE_LDMC.csv",sep=",",row.names=F)

#######################
## FRic4 - eMNTD    ###
#######################

modList22=list(
  lme(eMNTD~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(FRic4~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(GrossAsynchrony_s~lg2SppN+FRic4+eMNTD+sdAridity + lg2_mArid,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(TS_lg2~GrossAsynchrony_s+eMNTD+FRic4+LDMC+lg2SppN+sdAridity + lg2_mArid,random=~1+lg2SppN|Site, control=cc,data=stab_555)
)

lapply(modList22, plot)

# Explore distribution of residuals

lapply(modList22, function(i) hist(resid(i)))

# Look at variance inflation factors
lapply(modList22[3:4], vif)

sem.fit(modList22,stab_555,corr.errors=c("eMNTD~~FRic4"),conditional=T,
        model.control = list(lmeControl(opt = "optim"))) #naive model

emntdfric.fit<-sem.fit(modList22,stab_555,corr.errors=c("FRic4~~eMNTD","eMNTD ~~ LDMC"),conditional=T,
                       model.control = list(lmeControl(opt = "optim")))  # add eMNTD as predictor of TS

emntdfric.fit<-cbind(emntdfric.fit$Fisher.C,emntdfric.fit$AIC)
emntdfric.fit$ModClass<-"FRic_eMNTD_LDMC"

ts_emntd2<-sem.coefs(modList22,stab_555,standardize="scale",corr.errors=c("FRic4~~eMNTD","eMNTD ~~ LDMC"))
ts_emntd2$ModClass<-"FRic_eMNTD_LDMC"

mf_ts_emntd<-sem.model.fits(modList22)
mf_ts_emntd$ResponseVars<-c("eMNTD","FRic4","Asynchrony","Temp_Stability")
mf_ts_emntd$PredVars<-c("lg2SppN","lg2SppN","lg2SppN,eMNTD,FRic4,lg2_mArid,sdAridity","Asynchrony,eMNTD,LDMC, lg2SppN,lg2_mArid,sdAridity")
mf_ts_emntd$ModClass<-"FRic_eMNTD_LDMC"

#write out model results
write.table(ts_emntd2,"TS_emntd_fric_sem_coefs_SIMPLE_LDMC.csv",sep=",",row.names=F)
write.table(mf_ts_emntd,"TS_emntd_fric_model_fits_SIMPLE_LDMC.csv",sep=",",row.names=F)
write.table(emntdfric.fit,"TS_emntd_fric_semfit_SIMPLE_LDMC.csv",sep=",",row.names=F)

##################
# FDis_eMPD ######
##################

modList3=list(
  lme(eMPD~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(FDis4~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(GrossAsynchrony_s~lg2SppN+FDis4+eMPD+sdAridity + lg2_mArid,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(TS_lg2~GrossAsynchrony_s+LDMC+lg2SppN+FDis4+eMPD+sdAridity + lg2_mArid,random=~1+lg2SppN|Site, control=cc,data=stab_555)
)

lapply(modList3, plot)

# Explore distribution of residuals

lapply(modList3, function(i) hist(resid(i)))

# Look at variance inflation factors
lapply(modList3[3:4], vif)

sem.fit(modList3,stab_555,corr.errors=c("eMPD~~FDis4"),conditional=T,
        model.control = list(lmeControl(opt = "optim"))) #naive model

empdfdis.fit<-sem.fit(modList3,stab_555,corr.errors=c("eMPD~~FDis4","eMPD ~~ LDMC", "FDis4 ~~ LDMC"),conditional=T,
                      model.control = list(lmeControl(opt = "optim")))  # 

empdfdis.fit<-cbind(empdfdis.fit$Fisher.C,empdfdis.fit$AIC)
empdfdis.fit$ModClass<-"FDis_eMPD_LDMC"

ts_empd2<-sem.coefs(modList3,stab_555,standardize="scale",corr.errors=c("eMPD~~FDis4","eMPD ~~ LDMC", "FDis4 ~~ LDMC"))
ts_empd2$ModClass<-"FDis_eMPD_LDMC"

mf_ts_empd<-sem.model.fits(modList3)
mf_ts_empd$ResponseVars<-c("eMPD","FDis4","Asynchrony","Temp_Stability")
mf_ts_empd$PredVars<-c("lg2SppN","lg2SppN","lg2SppN,eMPD,FDis4,lg2_mArid,sdAridity","Asynchrony,lg2SppN,LDMC, lg2_mArid,sdAridity")
mf_ts_empd$ModClass<-"FDis_eMPD_LDMC"

#write out model results
write.table(ts_empd2,"TS_empd_fdis_sem_coefs_SIMPLE_LDMC.csv",sep=",",row.names=F)
write.table(mf_ts_empd,"TS_empd_fdis_model_fits_SIMPLE_LDMC.csv",sep=",",row.names=F)
write.table(empdfdis.fit,"TS_empd_fdis_semfit_SIMPLE_LDMC.csv",sep=",",row.names=F)

#######################
## FRic - eMPD #######
#######################

modList33=list(
  lme(eMPD~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(FRic4~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(GrossAsynchrony_s~lg2SppN+FRic4+eMPD+sdAridity + lg2_mArid,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(TS_lg2~GrossAsynchrony_s+LDMC+lg2SppN+FRic4+eMPD+sdAridity + lg2_mArid,random=~1+lg2SppN|Site, control=cc,data=stab_555)
)

lapply(modList33, plot)

# Explore distribution of residuals

lapply(modList33, function(i) hist(resid(i)))

# Look at variance inflation factors
lapply(modList33[3:4], vif)


sem.fit(modList33,stab_555,corr.errors=c("eMPD~~FRic4"),conditional=T,
        model.control = list(lmeControl(opt = "optim"))) #naive model

smpdfdis.fit<-sem.fit(modList33,stab_555,corr.errors=c("eMPD~~FRic4","eMPD ~~ LDMC"),conditional=T,
                      model.control = list(lmeControl(opt = "optim")))  


smpdfdis.fit<-cbind(smpdfdis.fit$Fisher.C,smpdfdis.fit$AIC)
smpdfdis.fit$ModClass<-"FRic4_eMPD_LDMC"

ts_smpd2<-sem.coefs(modList33,stab_555,standardize="scale",corr.errors=c("eMPD~~FRic4","eMPD ~~ LDMC"))
ts_smpd2$ModClass<-"FRic4_eMPD_LDMC"


mf_ts_smpd<-sem.model.fits(modList33)
mf_ts_smpd$ResponseVars<-c("eMPD","FRic4","Asynchrony","Temp_Stability")
mf_ts_smpd$PredVars<-c("lg2SppN","lg2SppN","lg2SppN,eMPD,FRic4,lg2_mArid,sdAridity","Asynchrony,LDMC,lg2SppN,lg2_mArid,sdAridity")
mf_ts_smpd$ModClass<-"FRic4_eMPD_LDMC"

# write out model results
write.table(ts_smpd2,"TS_empd_fric_sem_coefs_SIMPLE_LDMC.csv",sep=",",row.names=F)
write.table(mf_ts_smpd,"TS_empd_fric_model_fits_SIMPLE_LDMC.csv",sep=",",row.names=F)
write.table(smpdfdis.fit,"TS_empd_fric_semfit_SIMPLE_LDMC.csv",sep=",",row.names=F)

#######################
# Leaf N ##############
#######################

##################
# FDis_eMNTD #####
##################

bb<-lmeControl(msMaxIter=0,msVerbose = TRUE,opt="optim",maxIter=100,optimMEthod="L-BFGS-B")  ######## "msMaxIter=0" is important in here!!!
cc<-lmeControl(opt="optim")

modList2=list(
  lme(eMNTD~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(FDis4~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(GrossAsynchrony_s~lg2SppN+FDis4+eMNTD+sdAridity + lg2_mArid,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(TS_lg2~GrossAsynchrony_s+LeafN+FDis4+eMNTD+lg2SppN+sdAridity + lg2_mArid,random=~1+lg2SppN|Site, control=cc,data=stab_555)
)

lapply(modList2, plot)

# Explore distribution of residuals

lapply(modList2, function(i) hist(resid(i)))

# Look at variance inflation factors
lapply(modList2[3:4], vif)

sem.fit(modList2,stab_555,corr.errors=c("eMNTD~~FDis4"),conditional=T,
        model.control = list(lmeControl(opt = "optim"))) #naive model

emntdfdis.fit<-sem.fit(modList2,stab_555,corr.errors=c("eMNTD~~FDis4"),conditional=T,
                       model.control = list(lmeControl(opt = "optim")))  

emntdfdis.fit<-cbind(emntdfdis.fit$Fisher.C,emntdfdis.fit$AIC)
emntdfdis.fit$ModClass<-"FDis_eMNTD_LeafN"

ts_emntd2<-sem.coefs(modList2,stab_555,standardize="scale",corr.errors=c("eMNTD~~FDis4"))
ts_emntd2$ModClass<-"FDis_eMNTD_LeafN"

mf_ts_emntd<-sem.model.fits(modList2)
mf_ts_emntd$ResponseVars<-c("eMNTD","FDis4","Asynchrony","Temp_Stability")
mf_ts_emntd$PredVars<-c("lg2SppN","lg2SppN","lg2SppN,eMNTD,FDis4, lg2_mArid,sdAridity","eMNTD,Asynchrony,lg2SppN, LeafN, lg2_mArid,sdAridity")
mf_ts_emntd$ModClass<-"FDis_eMNTD_LeafN"

#write out model results
write.table(ts_emntd2,"TS_emntd_fdis_sem_coefs_SIMPLE_LeafN.csv",sep=",",row.names=F)
write.table(mf_ts_emntd,"TS_emntd_fdis_model_fits_SIMPLE_LeafN.csv",sep=",",row.names=F)
write.table(emntdfdis.fit,"TS_emntd_fdis_semfit_SIMPLE_LeafN.csv",sep=",",row.names=F)

#######################
## FRic4 - eMNTD    ###
#######################

modList22=list(
  lme(eMNTD~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(FRic4~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(GrossAsynchrony_s~lg2SppN+FRic4+eMNTD+sdAridity + lg2_mArid,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(TS_lg2~GrossAsynchrony_s+LeafN+lg2SppN+FRic4+eMNTD+sdAridity + lg2_mArid,random=~1+lg2SppN|Site, control=cc,data=stab_555)
)

lapply(modList22, plot)

# Explore distribution of residuals

lapply(modList22, function(i) hist(resid(i)))

# Look at variance inflation factors
lapply(modList22[3:4], vif)

sem.fit(modList22,stab_555,corr.errors=c("eMNTD~~FRic4"),conditional=T,
        model.control = list(lmeControl(opt = "optim"))) #naive model

emntdfric.fit<-sem.fit(modList22,stab_555,corr.errors=c("eMNTD~~FRic4","FRic4 ~~ LeafN"),conditional=T,
                       model.control = list(lmeControl(opt = "optim")))  # add eMNTD as predictor of TS

emntdfric.fit<-cbind(emntdfric.fit$Fisher.C,emntdfric.fit$AIC)
emntdfric.fit$ModClass<-"FRic_eMNTD_LeafN"

ts_emntd2<-sem.coefs(modList22,stab_555,standardize="scale",corr.errors=c("eMNTD~~FRic4","FRic4 ~~ LeafN"))
ts_emntd2$ModClass<-"FRic_eMNTD_LeafN"

mf_ts_emntd<-sem.model.fits(modList22)
mf_ts_emntd$ResponseVars<-c("eMNTD","FRic4","Asynchrony","Temp_Stability")
mf_ts_emntd$PredVars<-c("lg2SppN","lg2SppN","lg2SppN,eMNTD,FRic4,lg2_mArid,sdAridity","Asynchrony,eMNTD,LeafN, lg2SppN,lg2_mArid,sdAridity")
mf_ts_emntd$ModClass<-"FRic_eMNTD_LeafN"

# write out model results
write.table(ts_emntd2,"TS_emntd_fric_sem_coefs_SIMPLE_LeafN.csv",sep=",",row.names=F)
write.table(mf_ts_emntd,"TS_emntd_fric_model_fits_SIMPLE_LeafN.csv",sep=",",row.names=F)
write.table(emntdfric.fit,"TS_emntd_fric_semfit_SIMPLE_LeafN.csv",sep=",",row.names=F)

##################
# FDis_eMPD ######
##################

modList3=list(
  lme(eMPD~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(FDis4~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(GrossAsynchrony_s~lg2SppN+FDis4+eMPD+sdAridity + lg2_mArid,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(TS_lg2~GrossAsynchrony_s+LeafN+lg2SppN+FDis4+eMPD+sdAridity + lg2_mArid,random=~1+lg2SppN|Site, control=cc,data=stab_555)
)


lapply(modList3, plot)

# Explore distribution of residuals

lapply(modList3, function(i) hist(resid(i)))

# Look at variance inflation factors
lapply(modList3[3:4], vif)


sem.fit(modList3,stab_555,corr.errors=c("eMPD~~FDis4"),conditional=T,
        model.control = list(lmeControl(opt = "optim"))) #naive model

empdfdis.fit<-sem.fit(modList3,stab_555,corr.errors=c("eMPD~~FDis4"),conditional=T,
                      model.control = list(lmeControl(opt = "optim")))  # 

# write out model results
write.table(ts_empd2,"TS_empd_fdis_sem_coefs_SIMPLE_LeafN.csv",sep=",",row.names=F)
write.table(mf_ts_empd,"TS_empd_fdis_model_fits_SIMPLE_LeafN.csv",sep=",",row.names=F)
write.table(empdfdis.fit,"TS_empd_fdis_semfit_SIMPLE_LeafN.csv",sep=",",row.names=F)

#######################
## FRic - eMPD #######
#######################

modList33=list(
  lme(eMPD~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(FRic4~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(GrossAsynchrony_s~lg2SppN+FRic4+eMPD+sdAridity + lg2_mArid,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(TS_lg2~GrossAsynchrony_s+LeafN+FRic4+eMPD+lg2SppN+sdAridity + lg2_mArid,random=~1+lg2SppN|Site, control=cc,data=stab_555)
)

lapply(modList33, plot)

# Explore distribution of residuals

lapply(modList33, function(i) hist(resid(i)))

# Look at variance inflation factors
lapply(modList33[3:4], vif)


sem.fit(modList33,stab_555,corr.errors=c("eMPD~~FRic4"),conditional=T,
        model.control = list(lmeControl(opt = "optim"))) #naive model

smpdfdis.fit<-sem.fit(modList33,stab_555,corr.errors=c("eMPD~~FRic4","FRic4 ~~ LeafN"),conditional=T,
                      model.control = list(lmeControl(opt = "optim")))  

smpdfdis.fit<-cbind(smpdfdis.fit$Fisher.C,smpdfdis.fit$AIC)
smpdfdis.fit$ModClass<-"FRic4_eMPD_LeafN"

ts_smpd2<-sem.coefs(modList33,stab_555,standardize="scale",corr.errors=c("eMPD~~FRic4","FRic4 ~~ LeafN"))
ts_smpd2$ModClass<-"FRic4_eMPD_LeafN"

mf_ts_smpd<-sem.model.fits(modList33)
mf_ts_smpd$ResponseVars<-c("eMPD","FRic4","Asynchrony","Temp_Stability")
mf_ts_smpd$PredVars<-c("lg2SppN","lg2SppN","lg2SppN,eMPD,FRic4,lg2_mArid,sdAridity","Asynchrony,LeafN,lg2SppN,lg2_mArid,sdAridity")
mf_ts_smpd$ModClass<-"FRic4_eMPD_LeafN"

# write out results
write.table(ts_smpd2,"TS_empd_fric_sem_coefs_SIMPLE_LeafN.csv",sep=",",row.names=F)
write.table(mf_ts_smpd,"TS_empd_fric_model_fits_SIMPLE_LeafN.csv",sep=",",row.names=F)
write.table(smpdfdis.fit,"TS_empd_fric_semfit_SIMPLE_LeafN.csv",sep=",",row.names=F)

#######################
# Leaf P ##############
#######################

##################
# FDis_eMNTD #####
##################

bb<-lmeControl(msMaxIter=0,msVerbose = TRUE,opt="optim",maxIter=100,optimMEthod="L-BFGS-B")  ######## "msMaxIter=0" is important in here!!!
cc<-lmeControl(opt="optim")

modList2=list(
  lme(eMNTD~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(FDis4~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(GrossAsynchrony_s~lg2SppN+FDis4+eMNTD+sdAridity + lg2_mArid,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(TS_lg2~GrossAsynchrony_s+LeafP+eMNTD+FDis4+lg2SppN+sdAridity + lg2_mArid,random=~1+lg2SppN|Site, control=cc,data=stab_555)
)

lapply(modList2, plot)

# Explore distribution of residuals

lapply(modList2, function(i) hist(resid(i)))

# Look at variance inflation factors
lapply(modList2[3:4], vif)

sem.fit(modList2,stab_555,corr.errors=c("eMNTD~~FDis4"),conditional=T,
        model.control = list(lmeControl(opt = "optim"))) #naive model

emntdfdis.fit<-sem.fit(modList2,stab_555,corr.errors=c("eMNTD~~FDis4"," FDis4 ~~ LeafP"),conditional=T,
                       model.control = list(lmeControl(opt = "optim")))  


emntdfdis.fit<-cbind(emntdfdis.fit$Fisher.C,emntdfdis.fit$AIC)
emntdfdis.fit$ModClass<-"FDis_eMNTD_LeafP"

ts_emntd2<-sem.coefs(modList2,stab_555,standardize="scale",corr.errors=c("eMNTD~~FDis4"," FDis4 ~~ LeafP"))
ts_emntd2$ModClass<-"FDis_eMNTD_LeafP"

mf_ts_emntd<-sem.model.fits(modList2)
mf_ts_emntd$ResponseVars<-c("eMNTD","FDis4","Asynchrony","Temp_Stability")
mf_ts_emntd$PredVars<-c("lg2SppN","lg2SppN","lg2SppN,eMNTD,FDis4, lg2_mArid,sdAridity","eMNTD,Asynchrony,lg2SppN, LeafP, lg2_mArid,sdAridity")
mf_ts_emntd$ModClass<-"FDis_eMNTD_LeafP"

# write out model results
write.table(ts_emntd2,"TS_emntd_fdis_sem_coefs_SIMPLE_LeafP.csv",sep=",",row.names=F)
write.table(mf_ts_emntd,"TS_emntd_fdis_model_fits_SIMPLE_LeafP.csv",sep=",",row.names=F)
write.table(emntdfdis.fit,"TS_emntd_fdis_semfit_SIMPLE_LeafP.csv",sep=",",row.names=F)

#######################
## FRic4 - eMNTD    ###
#######################

modList22=list(
  lme(eMNTD~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(FRic4~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(GrossAsynchrony_s~lg2SppN+FRic4+eMNTD+sdAridity + lg2_mArid,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(TS_lg2~GrossAsynchrony_s+eMNTD+FRic4+LeafP+lg2SppN+sdAridity + lg2_mArid,random=~1+lg2SppN|Site, control=cc,data=stab_555)
)

lapply(modList22, plot)

# Explore distribution of residuals

lapply(modList22, function(i) hist(resid(i)))

# Look at variance inflation factors
lapply(modList22[3:4], vif)

sem.fit(modList22,stab_555,corr.errors=c("eMNTD~~FRic4"),conditional=T,
        model.control = list(lmeControl(opt = "optim"))) #naive model

emntdfric.fit<-sem.fit(modList22,stab_555,corr.errors=c("eMNTD~~FRic4","FRic4 ~~ LeafP"),conditional=T,
                       model.control = list(lmeControl(opt = "optim")))  # add eMNTD as predictor of TS

emntdfric.fit<-cbind(emntdfric.fit$Fisher.C,emntdfric.fit$AIC)
emntdfric.fit$ModClass<-"FRic_eMNTD_LeafP"

ts_emntd2<-sem.coefs(modList22,stab_555,standardize="scale",corr.errors=c("eMNTD~~FRic4","FRic4 ~~ LeafP"))
ts_emntd2$ModClass<-"FRic_eMNTD_LeafP"

mf_ts_emntd<-sem.model.fits(modList22)
mf_ts_emntd$ResponseVars<-c("eMNTD","FRic4","Asynchrony","Temp_Stability")
mf_ts_emntd$PredVars<-c("lg2SppN","lg2SppN","lg2SppN,eMNTD,FRic4,lg2_mArid,sdAridity","Asynchrony,eMNTD,LeafP, lg2SppN,lg2_mArid,sdAridity")
mf_ts_emntd$ModClass<-"FRic_eMNTD_LeafP"

# write out model results
write.table(ts_emntd2,"TS_emntd_fric_sem_coefs_SIMPLE_LeafP.csv",sep=",",row.names=F)
write.table(mf_ts_emntd,"TS_emntd_fric_model_fits_SIMPLE_LeafP.csv",sep=",",row.names=F)
write.table(emntdfric.fit,"TS_emntd_fric_semfit_SIMPLE_LeafP.csv",sep=",",row.names=F)

##################
# FDis_eMPD ######
##################

modList3=list(
  lme(eMPD~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(FDis4~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(GrossAsynchrony_s~lg2SppN+FDis4+eMPD+sdAridity + lg2_mArid,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(TS_lg2~GrossAsynchrony_s+LeafP+lg2SppN+FDis4+eMPD+sdAridity + lg2_mArid,random=~1+lg2SppN|Site, control=cc,data=stab_555)
)


lapply(modList3, plot)

# Explore distribution of residuals

lapply(modList3, function(i) hist(resid(i)))

# Look at variance inflation factors
lapply(modList3[3:4], vif)


sem.fit(modList3,stab_555,corr.errors=c("eMPD~~FDis4"),conditional=T,
        model.control = list(lmeControl(opt = "optim"))) #naive model

empdfdis.fit<-sem.fit(modList3,stab_555,corr.errors=c("eMPD~~FDis4","FDis4 ~~ LeafP"),conditional=T,
                      model.control = list(lmeControl(opt = "optim")))  # 

empdfdis.fit<-cbind(empdfdis.fit$Fisher.C,empdfdis.fit$AIC)
empdfdis.fit$ModClass<-"FDis_eMPD_LeafP"

ts_empd2<-sem.coefs(modList3,stab_555,standardize="scale",corr.errors=c("eMPD~~FDis4","FDis4 ~~ LeafP"))
ts_empd2$ModClass<-"FDis_eMPD_LeafP"


mf_ts_empd<-sem.model.fits(modList3)
mf_ts_empd$ResponseVars<-c("eMPD","FDis4","Asynchrony","Temp_Stability")
mf_ts_empd$PredVars<-c("lg2SppN","lg2SppN","lg2SppN,eMPD,FDis4,lg2_mArid,sdAridity","Asynchrony,lg2SppN,LeafP, lg2_mArid,sdAridity")
mf_ts_empd$ModClass<-"FDis_eMPD_LeafP"

# write out model results
write.table(ts_empd2,"TS_empd_fdis_sem_coefs_SIMPLE_LeafP.csv",sep=",",row.names=F)
write.table(mf_ts_empd,"TS_empd_fdis_model_fits_SIMPLE_LeafP.csv",sep=",",row.names=F)
write.table(empdfdis.fit,"TS_empd_fdis_semfit_SIMPLE_LeafP.csv",sep=",",row.names=F)

#######################
## FRic - eMPD #######
#######################

modList33=list(
  lme(eMPD~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(FRic4~lg2SppN,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(GrossAsynchrony_s~lg2SppN+FRic4+eMPD+sdAridity + lg2_mArid,random=~1+lg2SppN|Site,control=cc,data=stab_555),
  lme(TS_lg2~GrossAsynchrony_s+LeafP+lg2SppN+FRic4+eMPD+sdAridity + lg2_mArid,random=~1+lg2SppN|Site, control=cc,data=stab_555)
)


lapply(modList33, plot)

# Explore distribution of residuals

lapply(modList33, function(i) hist(resid(i)))

# Look at variance inflation factors
lapply(modList33[3:4], vif)


sem.fit(modList33,stab_555,corr.errors=c("eMPD~~FRic4"),conditional=T,
        model.control = list(lmeControl(opt = "optim"))) #naive model

smpdfdis.fit<-sem.fit(modList33,stab_555,corr.errors=c("eMPD~~FRic4","FRic4 ~~ LeafP"),conditional=T,
                      model.control = list(lmeControl(opt = "optim")))  


smpdfdis.fit<-cbind(smpdfdis.fit$Fisher.C,smpdfdis.fit$AIC)
smpdfdis.fit$ModClass<-"FRic4_eMPD_LeafP"

ts_smpd2<-sem.coefs(modList33,stab_555,standardize="scale",corr.errors=c("eMPD~~FRic4","FRic4 ~~ LeafP"))
ts_smpd2$ModClass<-"FRic4_eMPD_LeafP"

mf_ts_smpd<-sem.model.fits(modList33)
mf_ts_smpd$ResponseVars<-c("eMPD","FRic4","Asynchrony","Temp_Stability")
mf_ts_smpd$PredVars<-c("lg2SppN","lg2SppN","lg2SppN,eMPD,FRic4,lg2_mArid,sdAridity","Asynchrony,LeafP,lg2SppN,lg2_mArid,sdAridity")
mf_ts_smpd$ModClass<-"FRic4_eMPD_LeafP"

# write out model results
write.table(ts_smpd2,"TS_empd_fric_sem_coefs_SIMPLE_LeafP.csv",sep=",",row.names=F)
write.table(mf_ts_smpd,"TS_empd_fric_model_fits_SIMPLE_LeafP.csv",sep=",",row.names=F)
write.table(smpdfdis.fit,"TS_empd_fric_semfit_SIMPLE_LeafP.csv",sep=",",row.names=F)