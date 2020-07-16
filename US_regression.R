load("../Results/US_data_regression.RData")
source("optdim.R")
cat="inc" # "acc" This variable indicates whether incident death or accumulate death
steps=7 # number of steps of prediction used in the ensemble model
model.names=c("Geneva","YYG") # individual models to be combined
n.models= length(model.names) # number of individual models to be combined
Dum=1
pos.cons=1 # whether there is positive constraints for ceofficients
sim.num=100 # number of random draws from predictive posterior distribution

####----- 
#                                                      Bayesian inference  with Conjugate priors.
# sigma^2 is Inverse-Gamma distributed, beta is conditionally distributed as normal distribution
pred.Y=c()

library(invgamma)
library(MASS)
num.para= 1+ n.models*steps + 1 + 1*Dum # number of parameters = intercept + coefficients + sigma + dummyvariable
priors.dist=list(beta=list(mu=rep(1/(num.para-1),num.para-1),cv=diag(10^2,num.para-1,num.para-1)),sig=c(a0=0.1,b0=0.1))
#hyperparameters
Delta_0 = solve( priors.dist$beta$cv)
mu_0 = priors.dist$beta$mu
a_0=priors.dist$sig["a0"]
b_0 = priors.dist$sig["b0"]

# MCMC-Gibbs sampler
iter.num=2000
coef.mat=matrix(NA,iter.num,num.para)
coef.list=vector("list",nrow(us_wide_log))
y.hat.list=vector("list",nrow(us_wide_log))
var.names=as.vector(t(outer(paste0(model.names,"_"),c(1:steps),FUN = "paste0"))) #  model predictions for ensembling
if(Dum){
  var.names = c(var.names,"week")
}

for(i in 1:(nrow(us_wide_log)-1)){
  X=cbind(1,as.matrix(us_wide_log[1:i,var.names]))
  y=as.matrix(us_wide_log[1:i,"gt"])
  y.hat=matrix(NA,iter.num,length(y))
  Delta_n = Delta_0 + t(X)%*%X
  iDelta_n = solve(Delta_n)
  mu_n = solve(Delta_n)%*% (Delta_0 %*% mu_0 + t(X)%*% y)
  a_n = a_0  + i/2 # posterior parameter of sigma^2
  b_n = b_0 + 0.5* (t(y)%*%y + t(as.matrix(mu_0))%*% Delta_0 %*% as.matrix(mu_0) - t(mu_n) %*% Delta_n%*% mu_n)
  for(iter in 1:iter.num){
    coef.mat[iter,num.para] = rinvgamma(n=1,shape = a_n, scale = b_n) # draw sigma^2 
    coef.mat[iter,-num.para] = mvrnorm(n=1,mu=mu_n,Sigma = coef.mat[iter,num.para]* iDelta_n)
    y.hat[iter,]= X%*%coef.mat[iter,-num.para]
  }
  colnames(coef.mat)=c("Intercept",var.names,"variance")
  coef.list[[i]] = coef.mat
  y.hat.list[[i]]= y.hat
  
  # predict y for next step using the posterior samples of parameters
  X.new=cbind(1,us_wide_log[(1+i),var.names])

  if(!anyNA(X.new)){
    pred.mean=as.matrix(X.new)%*% t(coef.mat[,c("Intercept",var.names)])
    temp.Y=c()
    for(ii in 1:length(pred.mean)){
      temp.Y=c(temp.Y, rnorm(n=sim.num,mean=pred.mean[ii],sd=sqrt(coef.mat[ii,num.para])))
    }
    pred.Y= rbind(pred.Y, temp.Y) # incorporating the coef and sigma
  }
}

coef.df=c()
for(i in 1:nrow(us_wide_log)){
  coef.df=rbind(coef.df,cbind(time=i,coef.list[[i]])) # convert the list to dataframe
}
coef.df=as_tibble(coef.df) %>% pivot_longer(.,cols=-time,names_to = "Variables",values_to = "Coefficient")

burnin=3

g <- filter(coef.df,Variables!="variance",time>burnin) %>% ggplot(.,aes(x=factor(time),y=Coefficient,fill=factor(time))) + geom_boxplot() +facet_wrap(facets = vars(Variables),nrow = optdim(num.para)[1],ncol = optdim(num.para)[2]) + theme(axis.text.x = element_text( angle = 90,size =3),legend.position = "none")  + scale_x_discrete(name ="Date",breaks=c((burnin+1):nrow(us_wide)), labels=unique(us_wide_log$target_end_date)[(burnin+1):nrow(us_wide)]) 
g
ggsave(filename = paste0("../Results/BLR/US_coef_step",steps,"dum",Dum, ".pdf"),height = 5,width = 5)

#-----------------------------------------------------
###    Bayesian inference with Conjugate priors. Training VS. Prediction
  # MCMC-Gibbs sampler

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



## Appendix extra
####----
### ---------------------------Bayesian inference without positive constraints on uniform priors
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
#-------------------------------------------
### Bayesian inference with positive constraints on uniform priors
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
