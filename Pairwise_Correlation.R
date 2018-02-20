require(dplyr)
require(psych)
require(reshape2)
require(metafor)
require(corrplot)

is.nan.data.frame <- function(x)
  do.call(cbind, lapply(x, is.nan))


# Data
stab<-read.delim("/homes/dc78cahe/Dropbox (iDiv)/Research_projects/leipzigPhyTrt/StabilityII_data/Community_Level/Stab_Stability_FD_PD_CWM_PlotYearAverages_VI.csv",sep=",",header=T)

stab<-filter(stab,Site!="BIODEPTH_GR")  # should get rid of site where we didn't have good trait coverage

stab_4<-select(stab,Site,Study_length,UniqueID,SppN,eMPD,eMNTD,ePSE,sMPD,sMNTD,FDis4,FRic4,PCAdim1_4trts,SLA, LDMC, LeafN, LeafP,
               Plot_TempStab,Plot_Biomassxbar, Plot_Biomasssd,Plot_Asynchrony, Gross_synchrony, Loreau_synchrony,annualTemp,meanPrecip,meanPET,CV_Temp,CV_Precip)


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

# Filter out NAs for Asynchrony and  FRic4
stab_444<-filter(stab_4, is.na(PlotAsynchrony_s)==FALSE)
stab_444<-filter(stab_444, is.na(FRic4)==FALSE)


#################################
# calculate correlations among  #
# all predictors of TS ##########
#################################

stab_corr<-select(stab_444,Site,SppN, eMNTD,eMPD,FDis4,FRic4,PCAdim1_4trts,GrossAsynchrony_s,Plot_Biomassxbar,Plot_Biomasssd)

n<-length(unique(stab_corr$Site))

outt=c();

for(i in 1:n){
  
  test=subset(stab_corr, stab_corr$Site==(unique(stab_corr$Site))[i]) 
  
  Site<-as.character(unique(test$Site))
  Plot_n<-dim(test)[1]
  test<-select(test,-Site)
  
  p_out<-corr.test(test,method="pearson")
  p_outt<-as.matrix(p_out$r)
  p_outt<-data.frame(Var1=rownames(p_outt)[row(p_outt)[upper.tri(p_outt)]], 
                     Var2=colnames(p_outt)[col(p_outt)[upper.tri(p_outt)]], 
             corr=p_outt[upper.tri(p_outt)])
  
  p_outt$Site<-Site
  p_outt$Plot_n<-Plot_n

    outt[[i]]<-rbind.data.frame(p_outt)
  
}

jjj<-do.call(rbind,outt)  
jjj<-data.frame(jjj)

jjj<-filter(jjj, is.na(corr)==FALSE)

#Calculate effect size (raw correlation coefficient)

effect_size<-select(jjj,Site, Plot_n,Var1,Var2, corr)
effect_size<-escalc(measure="COR",ri=corr,ni=Plot_n,data=effect_size)

######### 

effect_size$Combn<-paste(effect_size$Var1,effect_size$Var2,sep="_")

n<-length(unique(effect_size$Combn))

outt=c();

for(i in 1:n){
  
  test=subset(effect_size, effect_size$Combn==(unique(effect_size$Combn))[i]) 

  Combn<-as.character(unique(test$Combn))
  Var1<-as.character(unique(test$Var1))
  Var2<-as.character(unique(test$Var2))
  
    Mod1<-rma.uni(yi,vi,measure="GEN",test="knha",method="REML",data=test)

  outt_p<-cbind.data.frame(Var1, Var2,Combn,Mod1$b,Mod1$ci.lb,Mod1$ci.ub)
  outt[[i]]<-rbind.data.frame(outt_p)
  
}

jjj<-do.call(rbind,outt)  
jjj<-data.frame(jjj)

colnames(jjj)[4]<-"r"
colnames(jjj)[5]<-"lower95"
colnames(jjj)[6]<-"upper95"

jjj<-arrange(jjj,Var1,Var2)


write.table(jjj,"/homes/dc78cahe/Dropbox (iDiv)/Research_projects/leipzigPhyTrt/StabilityII_data/Community_Level/Div_Corr_Effsizes_Jan2018.csv",sep=",",row.names=F)

############################
# make correlation matrix  #
############################

require(reshape2)
require(viridis)

jjj<-read.delim("/homes/dc78cahe/Dropbox (iDiv)/Research_projects/leipzigPhyTrt/StabilityII_data/Community_Level/Div_Corr_Effsizes_Jan2018.csv",sep=",",header=T)

#jjj<-filter(jjj,Var1=="SppN"|Var1=="FDis4" | Var1=="FRic4"|Var1=="eMNTD"|Var1=="PCAdim1_4trts" |Var1=="PlotAsynchrony_s")
#jjj<-filter(jjj,Var2=="SppN"|Var2=="FDis4" | Var2=="FRic4"|Var2=="eMNTD"|Var2=="PCAdim1_4trts"| Var2=="PlotAsynchrony_s")

#jjj<-filter(jjj,Var1!="eMPD")
#jjj<-filter(jjj,Var2!="eMPD")

corr_mat<-dcast(jjj,Var1~Var2,value.var="r",mean)

corr_mat<-arrange(corr_mat,-eMNTD)

corr_mat$Var1<-as.character(corr_mat$Var1)
corr_mat$Var1<-ifelse(corr_mat$Var1=="PCAdim1_4trts","F-S",corr_mat$Var1)
corr_mat$Var1<-ifelse(corr_mat$Var1=="GrossAsynchrony_s","Async",corr_mat$Var1)
corr_mat$Var1<-ifelse(corr_mat$Var1=="FRic4","FR",corr_mat$Var1)
corr_mat$Var1<-ifelse(corr_mat$Var1=="FDis4","FD",corr_mat$Var1)
corr_mat$Var1<-ifelse(corr_mat$Var1=="eMNTD","MNTD",corr_mat$Var1)
corr_mat$Var1<-ifelse(corr_mat$Var1=="eMPD","MPD",corr_mat$Var1)
corr_mat$Var1<-ifelse(corr_mat$Var1=="Plot_Biomassxbar","m Biom",corr_mat$Var1)


rownames(corr_mat)<-corr_mat$Var1

colnames(corr_mat)[2]<-"MNTD"
colnames(corr_mat)[3]<-"MPD"

colnames(corr_mat)[4]<-"FD"
colnames(corr_mat)[5]<-"FR"
colnames(corr_mat)[6]<-"F-S"
colnames(corr_mat)[7]<-"Async"
colnames(corr_mat)[8]<-"m Biom"
colnames(corr_mat)[9]<-"sd Biom"


corr_mat$Var1<-NULL

corr_mat[is.nan(corr_mat)] <- 0
corr_mat<-as.matrix(corr_mat)

col<- colorRampPalette(c("red", "white", "blue"))(256)

col2<-magma(256)

##################

png(filename="/homes/dc78cahe/Dropbox (iDiv)/Research_projects/leipzigPhyTrt/StabilityII_data/Community_Level/Div_Corr_Jan2018.png", 
    type="cairo",
    units="in", 
    width=7, 
    height=7 , 
    pointsize=2, 
    res=200)


corrplot(corr_mat, method="ellipse",type="upper",col=col,is.corr=TRUE,diag=TRUE,bg="white",tl.pos=TRUE,tl.cex=5,tl.col="black",tl.srt=0,cl.cex=5)

dev.off()

cairo_ps("/homes/dc78cahe/Dropbox (iDiv)/Research_projects/leipzigPhyTrt/StabilityII_data/Community_Level/Div_Corr_April2017.eps",
         family="sans",
         height=6,width=6,
         bg="white")

corrplot(corr_mat, method="ellipse",type="upper",col=col,is.corr=TRUE,diag=TRUE,bg="white",tl.pos=TRUE,tl.col="black",tl.srt=0)

dev.off()