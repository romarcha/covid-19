##########################################3 remove the first obs
model=lm(gt~. ,data=dat[,-c(1,2)])
fitted=model$fitted.values
# PCA 
X=t(dat[,-c(1,4)])
X.t=t(X)  # dimension of n*m
n=nrow(X.t)
X.c= X%*%(diag(rep(1,n))- 1/n*matrix(1,n,1)%*%matrix(1,1,n))
for(i in 1:3){X.c[i,]=X.c[i,]/sd(X.c[i,])}
K.c=(X.c)%*%t(X.c)/(n-1) # n*n
u=eigen(K.c)$vectors[,1]
u=u-min(u)
u=u/sum(u)

## Results
library(ggplot2)
dat=as_tibble(dat)
dat$forecast_date=as.Date(dat$forecast_date)
colors <- c("linear regression" = "blue", "PCA" = "green", "gt" = "red", "obs"="black","Mean"="pink")




cat(sum(abs(fitted-dat$gt)), "linear regression",'\n')
cat(sum(abs(lassofitted-dat$gt)), "Lasso",'\n')
cat(sum(abs(mean_v-dat$gt)),"mean",'\n')

# half for training, half for validation
model=lm(gt~. ,data=dat[1:20,])
predict(model,dat)

ts.plot(dat[,1:3],lwd=0.3,col=1:3)
lines(dat$gt,col='red',lwd=2)
#lines(pca_v2<-t(X)%*%u,col='lightblue',lwd=2)
lines((mean_v=rowMeans(dat[,-4])),col='green',lwd=2)
lines(predict(model,dat),col="blue",lwd=2)
legend("topright",legend = c("gt","Mean","Regression"),col=c("red","green","blue"),lwd=2)

fitted=model$fitted.values
