#################################################prepare the data
cat="inc" # "acc" This variable indicates whether incident death or accumulate death

us=read.csv('../raw-data/us_result.csv')
# gt=read.csv('../raw-data/gt.csv')
library(dplyr)
library(tidyr)
models= c("Geneva","YYG") # YYG and IHME predict USA and also states, Geneva only predicts USA
us=filter(us,model_name %in% models,location_long =="United States")

ahead=7 # decide how many days are included in the regression


us_part1=filter(us,model_name %in% models[1])

us_part1=group_by(us_part1,target_end_date,forecast_date,model_name,gt_source)
us_part1=summarise(us_part1,expected_value=sum(expected_value),gt=sum(gt),lookahead=mean(lookahead))

us_part2=filter(us,model_name %in% models[2]) # YYG predict USA and also states
us_part2=group_by(us_part2,target_end_date,forecast_date,model_name,gt_source)
us_part2=summarise(us_part2,expected_value=max(expected_value),gt=max(gt),lookahead=mean(lookahead))

us_group=bind_rows(us_part1,us_part2)

us_wide=pivot_wider(us_group,names_from = c("model_name"), values_from = expected_value) %>% filter(.,as.Date(forecast_date)>as.Date("2020-04-14")) %>%filter(.,lookahead<=ahead) %>%filter(.,gt>=0)  %>%filter(.,gt_source %in% c("JHU","ECDC"))  

for(i in 1:nrow(us_wide)){
  temp=filter(us_wide,forecast_date==us_wide$forecast_date[i],target_end_date==us_wide$target_end_date[i])
  us_wide[i,models[1]]=mean(as.matrix(temp[,models[1]]),na.rm = T)
  us_wide[i,models[2]]=mean(as.matrix(temp[,models[2]]),na.rm = T)
  
}

us_wide=ungroup(filter(us_wide,gt_source=="JHU")) %>% dplyr::select(.,-forecast_date,-gt_source)

us_wide=pivot_wider(us_wide,names_from = lookahead,values_from = c("Geneva","YYG"))
us_wide=drop_na(us_wide) %>% mutate(.,week=as.numeric(weekdays(as.Date(target_end_date)) %in% c("Saturday","Sunday","Monday"))) 
us_wide$target_end_date=as.Date(us_wide$target_end_date)
us_wide=us_wide[order(us_wide$target_end_date),]
## take the data into log-scale
us_wide_log=(us_wide)
us_wide_log[,c(2:16)]=log(us_wide_log[,c(2:16)])
####----
#   -----------------------------------------------------------Data is ready

####----
#------------------------------------------------------------------EDA plots
source('US_regression_EDA.R')

####----   
#---------------------------------------------------- regression (MLE version)
Dum=FALSE #FALSE
train.num=30 # split training and prediction set
if(Dum){
  model=lm(gt~. ,data=us_wide_log[1:train.num,-1])
} else{
  model=lm(gt~. ,data=us_wide_log[1:train.num,-c(1,ncol(us_wide_log))])
}

fitted=model$fitted.values
pred=c()
if(Dum){
  for(train in train.num:(nrow(us_wide_log)-1)){
    model=lm(gt~. ,data=us_wide_log[1:train,-1])
    pred=c(pred,predict.lm(model,newdata = us_wide_log[(train+1),-1]))}
} else{
  for(train in train.num:(nrow(us_wide_log)-1)){
    model=lm(gt~. ,data=us_wide_log[1:train,-c(1,ncol(us_wide_log))])
    pred=c(pred,predict.lm(model,newdata = us_wide_log[(train+1),-c(1,ncol(us_wide_log))]))}
}



plot(exp(us_wide_log$gt),type = 'l')
lines(c(1:train.num),exp(fitted),col="red")
lines(c((train.num+1):nrow(us_wide_log)),exp(pred),col="green",lty=2)
lines(us_wide$YYG_1,col='blue')
lines(us_wide$Geneva_1,col='blue',lty=2)
legend("topright",c("gt",'Fitted','Predicted',"YYG_1","Geneva_1"),lty = c(1,1,2,1,2),col=c('black','red','green','blue','blue'))

## Compare the combined model with single model prediction
sum(abs(us_wide$gt[(train.num+1):(nrow(us_wide_log))]-exp(pred))) # combined
sum(abs((us_wide$gt[(train.num+1):(nrow(us_wide_log))]-us_wide$YYG_1[(train.num+1):(nrow(us_wide_log))]))) # YYG_1



####----
##------------------------------------------------------------ Results
library(ggplot2)

us_wide_all=us_wide
us_wide_all$fitted = exp(c(fitted,pred))

us_long=pivot_longer(us_wide_all,cols=-c(target_end_date,week),names_to ="var",values_to = "deaths" )
us_long$target_end_date=as.Date(us_long$target_end_date)

ggplot(us_long, aes(x=target_end_date,y=deaths,colour=var)) + geom_line() + scale_colour_manual(values=c(Geneva_1="#AA0066",Geneva_2="#AA3399",Geneva_3="#339999",Geneva_4="#CC0033",Geneva_5="#FF6600",Geneva_6="#FF9933",Geneva_7="#FF9935",gt='black',YYG_1="#000066",YYG_2="#663399",YYG_3="#339999",YYG_4="#CC0033",YYG_5="#FF6600",YYG_6="#FF9933",YYG_7="#FF9933",fitted="green"))

ggplot(filter(us_long,var %in% c("gt","fitted")), aes(x=target_end_date,y=deaths,colour=var)) + geom_line() 

####----
### -------------Bayesian inference without constraints with uniform priors
priors.dist=matrix(c(c(-10^5,10^5),rep(c(-100,100),14),c(-10^5,10^5),c(0,500)),ncol=2,byrow=TRUE)
row.names(priors.dist)=c("inter",rep("coef",14),"week","sig")
log.post.likelihood=function(data,paras){
  #data is the data
  #paras is the parameters. [intercept,coefficients,week,sigmas]
  X=cbind(1,data[,-1])
  l=sum(dnorm(x=as.matrix(X)%*%paras[-length(paras)],mean = as.matrix(data[,1]),sd=paras[length(paras)],log = T) )
  return(l)
}
# starting points
train.num=36
model=lm(gt~. ,data=us_wide_log[1:train.num,-1])
paras=c(model$coefficients,sqrt(var(model$residuals)/length(model$residuals))) # use MLE of unconstrained linear regression

hyper=rep(0.5,length(paras))
counts=rep(0,length(paras))
acc.counts=rep(0,length(paras))
# tune the proposal hyperparameters
for(iter in 1:3000){
  for(i in 1:length(paras)){
    paras.new=paras
    paras.new[i]= rnorm(1,paras[i],hyper[i])
    if(paras.new[i] > priors.dist[i,1] && paras.new[i] < priors.dist[i,2]){
      counts[i]=counts[i]+1
      if(log.post.likelihood(data = us_wide_log[1:train.num,-1],paras =paras.new ) - log.post.likelihood(data=us_wide_log[1:train.num,-1],paras =paras ) > log(runif(1))){
        acc.counts[i]=acc.counts[i]+1
        paras=paras.new
      }
    }
  }
  
  if(iter %%200 ==0){ # update the hyperparameter
    acc=acc.counts/counts
    for(j in 1:length(acc)){
      if(acc[j]<0.44){
        hyper[j]=hyper[j]/(2^(200/iter))
      } else{hyper[j]=hyper[j]*(2^(200/iter))}
    }
    counts=rep(0,length(paras))
    acc.counts=rep(0,length(paras))
    cat("iteration=",iter,'\n')
  }
}

# MCMC
iter.num=2000
result.mat=matrix(NA,iter.num,length(paras))
y.hat=matrix(NA,iter.num,nrow(us_wide))
for(iter in 1:iter.num){
  for(i in 1:length(paras)){
    paras.new=paras
    paras.new[i]= rnorm(1,paras[i],hyper[i])
    if(paras.new[i] > priors.dist[i,1] && paras.new[i] < priors.dist[i,2]){
      counts[i]=counts[i]+1
      if(log.post.likelihood(data=us_wide_log[1:train.num,-1],paras =paras.new ) - log.post.likelihood(data=us_wide_log[1:train.num,-1],paras =paras ) > log(runif(1))){
        acc.counts[i]=acc.counts[i]+1
        paras=paras.new
      }
    }
  }
  result.mat[iter,]=paras
  temp=cbind(1,us_wide_log[1:train.num,-c(1,2)])
  y.hat[iter,]= as.matrix(temp)%*%paras[-length(paras)]
  if(iter%%500 ==0){cat("iteration=",iter)}
}
boxplot(exp(y.hat))
points(us_wide$gt,col='red')
lines(us_wide$gt,col='red')
#-----------------------------------------------------------------------------------------------------------------------------------------------
### Bayesian inference with constraints with uniform priors
priors.dist=matrix(c(c(-10^5,10^5),rep(c(0,100),14),c(-10^5,10^5),c(0,500)),ncol=2,byrow=TRUE)
row.names(priors.dist)=c("inter",rep("coef",14),"week","sig")

# starting points
train.num=36
model=lm(gt~. ,data=us_wide_log[1:train.num,-1])
paras=c(model$coefficients,sqrt(var(model$residuals)/length(model$residuals))) # use MLE of unconstrained linear regression
paras[ 2:(length(paras)-2)] =abs(paras[ 2:(length(paras)-2)])

hyper=rep(0.5,length(paras))
counts=rep(0,length(paras))
acc.counts=rep(0,length(paras))
# tune the proposal hyperparameters
for(iter in 1:4000){
  for(i in 1:length(paras)){
    paras.new=paras
    paras.new[i]= rnorm(1,paras[i],hyper[i])
    if(paras.new[i] > priors.dist[i,1] && paras.new[i] < priors.dist[i,2]){
      counts[i]=counts[i]+1
      if(log.post.likelihood(data = us_wide_log[1:train.num,-1],paras =paras.new ) - log.post.likelihood(data=us_wide_log[1:train.num,-1],paras =paras ) > log(runif(1))){
        acc.counts[i]=acc.counts[i]+1
        paras=paras.new
      }
    }
  }
  
  if(iter %%200 ==0){ # update the hyperparameter
    acc=acc.counts/counts
    for(j in 1:length(acc)){
      if(acc[j]<0.44){
        hyper[j]=hyper[j]/(2^(200/iter))
      } else{hyper[j]=hyper[j]*(2^(200/iter))}
    }
    counts=rep(0,length(paras))
    acc.counts=rep(0,length(paras))
    cat("iteration=",iter,'\n')
  }
}

# MCMC
iter.num=2000
result.mat=matrix(NA,iter.num,length(paras))
y.hat=matrix(NA,iter.num,nrow(us_wide))
for(iter in 1:iter.num){
  for(i in 1:length(paras)){
    paras.new=paras
    paras.new[i]= rnorm(1,paras[i],hyper[i])
    if(paras.new[i] > priors.dist[i,1] && paras.new[i] < priors.dist[i,2]){
      counts[i]=counts[i]+1
      if(log.post.likelihood(data=us_wide_log[1:train.num,-1],paras =paras.new ) - log.post.likelihood(data=us_wide_log[1:train.num,-1],paras =paras ) > log(runif(1))){
        acc.counts[i]=acc.counts[i]+1
        paras=paras.new
      }
    }
  }
  result.mat[iter,]=paras
  temp=cbind(1,us_wide_log[1:train.num,-c(1,2)])
  y.hat[iter,]= as.matrix(temp)%*%paras[-length(paras)]
  if(iter%%500 ==0){cat("iteration=",iter)}
}
save.image(file = "../Results/BLR/US_BLR_with_positive_prior.RData")
boxplot(exp(y.hat))
points(us_wide$gt,col='red')
lines(us_wide$gt,col='red')
####----
### Bayesian inference without constraints with Conjugate priors. try not to use the dummy variable
# sigma^2 is Inverse-Gamma distributed, beta is conditionally distributed as normal distribution
library(invgamma)
library(MASS)
train.num=36
num.para=16
X=cbind(1,as.matrix(us_wide_log[1:train.num,-c(1,2,ncol(us_wide_log))]))
y=as.matrix(us_wide_log[1:train.num,2])

priors.dist=list(beta=list(mu=rep(0,num.para-1),cv=diag(10^5,num.para-1,num.para-1)),sig=c(a0=0.0001,b0=0.0001))

#hyperparameters
Delta_0 = solve( priors.dist$beta$cv)
Delta_n = Delta_0 + t(X)%*%X
iDelta_n = solve(Delta_n)
mu_0 = priors.dist$beta$mu
mu_n = solve(Delta_n)%*% (Delta_0 %*% mu_0 + t(X)%*% y)
a_0=priors.dist$sig["a0"]
a_n = a_0  + nrow(us_wide_log[1:train.num,]) # posterior parameter of sigma^2
b_0 = priors.dist$sig["b0"]
b_n = b_0 + 0.5* (t(y)%*%y + t(as.matrix(mu_0))%*% Delta_0 %*% as.matrix(mu_0) - t(mu_n) %*% Delta_n%*% mu_n)


# starting points
model=lm(gt~. ,data=us_wide_log[1:train.num,-c(1,ncol(us_wide_log))])
paras=c(model$coefficients,(var(model$residuals)/length(model$residuals))) # use MLE of unconstrained linear regression


# MCMC-Gibbs sampler
iter.num=2000
result.mat=matrix(NA,iter.num,length(paras))
y.hat=matrix(NA,iter.num,nrow(us_wide))
for(iter in 1:iter.num){
  # draw sigma^2 
  result.mat[iter,length(paras)] = rinvgamma(n=1,shape = a_n, scale = b_n)
  result.mat[iter,-length(paras)] = mvrnorm(n=1,mu=mu_n,Sigma = result.mat[iter,length(paras)]* iDelta_n)
  
  temp=cbind(1,us_wide_log[,-c(1,2)])
  y.hat[iter,]= X%*%result.mat[iter,-length(paras)]
}
boxplot(exp(y.hat))
points(us_wide$gt,col='red')
lines(us_wide$gt,col='red')
title(main="gt VS. posterior samples of Y")

boxplot(result.mat)
points(model$coefficients,col='red')
title(main= " Comparison between MCMC and MLE of estimation")

####----
### Bayesian inference without constraints with Conjugate priors
# sigma^2 is Inverse-Gamma distributed, beta is conditionally distributed as normal distribution
library(invgamma)
library(MASS)
train.num=36
num.para=17
X=cbind(1,as.matrix(us_wide_log[1:train.num,-c(1,2)]))
y=as.matrix(us_wide_log[1:train.num,2])

priors.dist=list(beta=list(mu=rep(0,num.para-1),cv=diag(10^5,num.para-1,num.para-1)),sig=c(a0=0.0001,b0=0.0001))

#hyperparameters
Delta_0 = solve( priors.dist$beta$cv)
Delta_n = Delta_0 + t(X)%*%X
iDelta_n = solve(Delta_n)
mu_0 = priors.dist$beta$mu
mu_n = solve(Delta_n)%*% (Delta_0 %*% mu_0 + t(X)%*% y)
a_0=priors.dist$sig["a0"]
a_n = a_0  + nrow(us_wide_log[1:train.num,]) # posterior parameter of sigma^2
b_0 = priors.dist$sig["b0"]
b_n = b_0 + 0.5* (t(y)%*%y + t(as.matrix(mu_0))%*% Delta_0 %*% as.matrix(mu_0) - t(mu_n) %*% Delta_n%*% mu_n)


# starting points
model=lm(gt~. ,data=us_wide_log[1:train.num,-1])
paras=c(model$coefficients,(var(model$residuals)/length(model$residuals))) # use MLE of unconstrained linear regression


# MCMC-Gibbs sampler
iter.num=2000
result.mat=matrix(NA,iter.num,length(paras))
y.hat=matrix(NA,iter.num,nrow(us_wide))
for(iter in 1:iter.num){
  # draw sigma^2 
  result.mat[iter,length(paras)] = rinvgamma(n=1,shape = a_n, scale = b_n)
  result.mat[iter,-length(paras)] = mvrnorm(n=1,mu=mu_n,Sigma = result.mat[iter,length(paras)]* iDelta_n)
  
  temp=cbind(1,us_wide_log[,-c(1,2)])
  y.hat[iter,]= X%*%result.mat[iter,-length(paras)]
}
boxplot(exp(y.hat))
points(us_wide$gt,col='red')
lines(us_wide$gt,col='red')
title(main="gt VS. posterior samples of Y")

boxplot(result.mat)
points(model$coefficients,col='red')
title(main= " Comparison between MCMC and MLE of estimation")
#-----------------------------------------------------
###                Bayesian inference without constraints with Conjugate priors. Training VS. Prediction

Dum=TRUE  # include the dummy variable (week) or not. TRUE;FALSE
train.num.start=30
pred.Y=c()
coef.list=list()
if(Dum){num.para=17} else(num.para=16)


priors.dist=list(beta=list(mu=rep(1/(num.para-1),num.para-1),cv=diag(10^(5),num.para-1,num.para-1)),sig=c(a0=0.0001,b0=0.0001))

for(train.num in train.num.start:nrow(us_wide_log)){
  
  if(Dum){
    X=cbind(1,as.matrix(us_wide_log[1:train.num,-c(1,2)]))
  } else{
    X=cbind(1,as.matrix(us_wide_log[1:train.num,-c(1,2,ncol(us_wide_log))]))
  }
  
  y=as.matrix(us_wide_log[1:train.num,2])
  #hyperparameters
  Delta_0 = solve( priors.dist$beta$cv)
  Delta_n = Delta_0 + t(X)%*%X
  iDelta_n = solve(Delta_n)
  mu_0 = priors.dist$beta$mu
  mu_n = solve(Delta_n)%*% (Delta_0 %*% mu_0 + t(X)%*% y)
  a_0=priors.dist$sig["a0"]
  a_n = a_0  + nrow(us_wide_log[1:train.num,]) # posterior parameter of sigma^2
  b_0 = priors.dist$sig["b0"]
  b_n = b_0 + 0.5* (t(y)%*%y + t(as.matrix(mu_0))%*% Delta_0 %*% as.matrix(mu_0) - t(mu_n) %*% Delta_n%*% mu_n)
  # starting points
  if(Dum){
    model=lm(gt~. ,data=us_wide_log[1:train.num,-1])
    paras=c(model$coefficients,(var(model$residuals)/length(model$residuals))) # use MLE of unconstrained linear regression
  } else{
    model=lm(gt~. ,data=us_wide_log[1:train.num,-c(1,ncol(us_wide_log))])
    paras=c(model$coefficients,(var(model$residuals)/length(model$residuals))) # use MLE of unconstrained linear regression
  }
  
  
  # MCMC-Gibbs sampler
  iter.num=2000
  sim.num=100 # number of random draws from predictive posterior distribution
  result.mat=matrix(NA,iter.num,length(paras))
  y.hat=matrix(NA,iter.num,nrow(us_wide_log[1:train.num,]))
  for(iter in 1:iter.num){
    # draw sigma^2 
    result.mat[iter,length(paras)] = rinvgamma(n=1,shape = a_n, scale = b_n)
    result.mat[iter,-length(paras)] = mvrnorm(n=1,mu=mu_n,Sigma = result.mat[iter,length(paras)]* iDelta_n)
    
    temp=cbind(1,us_wide_log[,-c(1,2)])
    y.hat[iter,]= X%*%result.mat[iter,-length(paras)]
  }
  coef.list[[train.num-train.num.start+1]]=result.mat
  if(Dum){
    X.new=cbind(1,us_wide_log[(1+train.num),-c(1,2)])
  } else{
    X.new=cbind(1,us_wide_log[(1+train.num),-c(1,2,ncol(us_wide_log))])
  }
  
  if(!anyNA(X.new)){
    pred.mean=as.matrix(X.new)%*% t(result.mat[,-length(paras)])
    temp.Y=c()
    for(ii in 1:length(pred.mean)){
      temp.Y=c(temp.Y, rnorm(n=sim.num,mean=pred.mean[ii],sd=sqrt(result.mat[ii,length(paras)])))
    }
    pred.Y= rbind(pred.Y, temp.Y) # incorporating the coef and sigma
  }
}
train.part=exp(y.hat[,1:train.num.start])  
colnames(train.part) = as.character(us_wide_log$target_end_date[1:train.num.start]) 
train.part=pivot_longer(as_tibble(train.part),cols=everything(),names_to = "Target.Date",values_to = "Inc.death") %>% mutate(.,Category="train")
train.part$gt=rep(us_wide$gt[1:train.num.start],iter.num)
train.part$Date=rep(c(1:train.num.start),iter.num)

pred.part=exp(t(pred.Y))
colnames(pred.part)= as.character(us_wide_log$target_end_date[(1+train.num.start): nrow(us_wide_log)])
pred.part=pivot_longer(as_tibble(pred.part),cols=everything(),names_to = "Target.Date",values_to = "Inc.death")%>% mutate(.,Category="prediction")
pred.part$gt=rep(us_wide$gt[(1+train.num.start):nrow(us_wide_log)],iter.num*sim.num)
pred.part$Date=rep(c((1+train.num.start):nrow(us_wide_log)),iter.num*sim.num)
all.box=bind_rows(train.part,pred.part)
if(Dum){
  save.image(file = "../Results/BLR/US_BLR_Conjugate.RData")
} else{
  save.image(file = "../Results/BLR/US_BLR_Conjugate_without_dummy.RData")
}
pl<-ggplot(all.box,aes(x=factor(Date),y=Inc.death,fill=Category)) + geom_boxplot()+  theme(axis.text.x = element_text( angle = 90)) + geom_point(aes(x=factor(Date),y=gt))+geom_line(aes(x=Date,y=gt,color=Category)) + scale_x_discrete(name ="Date",breaks=c(1:nrow(us_wide)), labels=unique(us_wide_log$target_end_date)) 
if(Dum){
  ggsave(filename = "../Results/BLR/US_boxplot.pdf",plot = pl,width = 10, height = 10)
} else{
  ggsave(filename = "../Results/BLR/US_boxplot_without_dummy.pdf",plot = pl,width = 10, height = 10,device = 'jpeg')
}

if(Dum){
  ggsave(filename = "../Results/BLR/US_boxplot.jpeg",plot = pl,width = 10, height = 10)
} else{
  ggsave(filename = "../Results/BLR/US_boxplot_without_dummy.jpeg",plot = pl,width = 10, height = 10,device = 'jpeg')
}

pl<-ggplot(all.box,aes(x=factor(Date),y=Inc.death,fill=Category)) + geom_violin()+  theme(axis.text.x = element_text( angle = 90)) + geom_point(aes(x=(Date),y=gt))+geom_line(aes(x=Date,y=gt,color=Category)) + scale_x_discrete(name ="Date",breaks=c(1:nrow(us_wide)), labels=unique(us_wide_log$target_end_date))

if(Dum){
  ggsave(filename = "../Results/US_violin.pdf",plot = pl,width = 10, height = 10)
} else(
  ggsave(filename = "../Results/US_violin_without_dummy.pdf",plot = pl,width = 10, height = 10)
)

if(Dum){
  ggsave(filename = "../Results/BLR/US_violin.jpeg",plot = pl,width = 10, height = 10)
} else(
  ggsave(filename = "../Results/BLR/US_violin_without_dummy.jpeg",plot = pl,width = 10, height = 10)
)

# results of coefficients
coef.list=coef.list[1:(length(coef.list)-1)]
for (i in 1:length(coef.list)){
  temp=coef.list[[i]]
  colnames(temp)=c("Intercept",colnames(us_wide_log)[-c(1,2)],"variance")
  temp=pivot_longer(as_tibble(temp),cols=everything(),names_to = "Variable",values_to = "Value") %>% mutate(.,End_date=us_wide_log$target_end_date[train.num.start+i-1])
  coef.list[[i]]=temp
}
coef.tibble=as_tibble()
for (i in 1:length(coef.list)){
  coef.tibble=bind_rows(coef.tibble,coef.list[[i]])
}

pl=ggplot(coef.tibble,aes(x=Variable,y = Value,color=Variable)) + geom_boxplot() +theme(axis.text.x = element_text( angle = 90)) +facet_wrap( facets= vars(End_date),nrow = 2,ncol=3)
pl
ggsave(filename = "../Results/BLR/US_coef_boxplot.pdf",plot = pl,width = 10, height = 10)


## 

load(file = "../Results/BLR/US_BLR_Conjugate.RData")
Temp=filter(all.box,Category=="prediction")%>% mutate(.,Category="pred.dummy")
load(file = "../Results/BLR/US_BLR_Conjugate_without_dummy.RData")
mytemp=filter(all.box,Category=="prediction") %>% mutate(.,Category="pred.no.dummy")
Pred.all=bind_rows(filter(all.box,Category=="train") ,Temp,mytemp)

pl<-ggplot(Pred.all,aes(x=factor(Date),y=Inc.death,fill=Category)) + geom_violin()+  theme(axis.text.x = element_text( angle = 90)) + geom_point(aes(x=factor(Date),y=gt))+geom_line(aes(x=Date,y=gt,color=Category)) + scale_x_discrete(name ="Date",breaks=c(1:nrow(us_wide)), labels=unique(us_wide_log$target_end_date)) 
ggsave(filename = "../Results/BLR/US_violin_dummyVSno.jpeg",plot = pl,width = 10, height = 10)

pl<-ggplot(Pred.all,aes(x=factor(Date),y=Inc.death,fill=Category)) + geom_boxplot()+  theme(axis.text.x = element_text( angle = 90)) + geom_point(aes(x=factor(Date),y=gt))+geom_line(aes(x=Date,y=gt,color=Category)) + scale_x_discrete(name ="Date",breaks=c(1:nrow(us_wide)), labels=unique(us_wide_log$target_end_date)) 
ggsave(filename = "../Results/BLR/US_boxplot_dummyVSno.jpeg",plot = pl,width = 10, height = 10)

