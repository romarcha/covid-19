## 

## Data Generation
n=20 # number of prediction points
m=10 # number of models to combine
steps=10
X=matrix(rnorm(m*n),m,n)*matrix(3*c(rep(1,m*n/2),rep((m/2+1):(m),each=n)),m,n,byrow = T) + matrix(steps*rep(1:n,m),m,n,byrow = T) # normal noise

X=matrix(runif(m*n,0,5),m,n)*matrix(3*c(rep(1,m*n/2),rep((m/2+1):(m),each=n)),m,n,byrow = T) + matrix(steps*rep(1:n,m),m,n,byrow = T) # uniform noise

X=matrix(rnorm(m*n/2),m/2,n) + matrix(steps*rep(1:n,m/2),m/2,n,byrow = T)
X=rbind(X,matrix(rnorm(m*n/2),m/2,n) + matrix(steps*rep(n:1,m/2),m/2,n,byrow = T)) # reverse direction

X=matrix(rnorm(m*n/2),m/2,n)*5 + matrix(steps*rep(1:n,m/2),m/2,n,byrow = T)
X=rbind(X,matrix(rnorm(m*n/2),m/2,n)*1 + matrix(steps*rep(1:n,m/2)/3,m/2,n,byrow = T)) # same direction different slopes

X=matrix(rnorm(4*m*n/5),m*4/5,n)*5 + matrix(steps*rep(1:n,m*4/5),m*4/5,n,byrow = T)
X=rbind(X,matrix(rnorm(m*n/5),m/5,n)*1 + matrix(steps*rep(1:n,m/5)/2,m/5,n,byrow = T))




# Linear regression
dat=t(rbind(X,matrix(steps*rep(1:n,1),1,n,byrow = T)))
dat=as.data.frame(dat)
model=lm(V11~. ,data=dat)
fitted=model$fitted.values
##################################  PCA
X.t=t(X)  # dimension of n*m
X.c= X%*%(diag(rep(1,n))- 1/n*matrix(1,n,1)%*%matrix(1,1,n))
K.c=(X.c)%*%t(X.c)/(n-1) # n*n
u=eigen(K.c)$vectors[,1]
u=u-min(u)
u=u/sum(u)

## Results
ts.plot(t(X),lwd=0.3)
lines(pca_v2<-t(X)%*%u,col='red',lwd=2)
lines((mean_v=apply(X,2,mean)),col='green',lwd=2)
lines(fitted,col="blue",lwd=2)
legend("bottomright",legend = c("PCA","Mean","Regression"),col=c('red',"green","blue"),lwd=2)
cat(sum(abs((pca_v2)-steps*rep(1:n,1))),"PCA",'\n')
cat(sum(abs(fitted-steps*rep(1:n,1))), "linear regression",'\n')
cat(sum(abs((mean_v=apply(X,2,mean))-steps*rep(1:n,1))),"mean",'\n')




###  linear regression  for cosine
X=matrix(rnorm(m*n),m,n)*matrix(2*c(rep(1,m*n)),m,n,byrow = T) + matrix(steps*sin(rep(1:n,m)),m,n,byrow = T) # normal noise, cosine truth
dat=t(rbind(X,matrix(steps*sin(rep(1:n,1)),1,n,byrow = T)))
dat=as.data.frame(dat)
model=lm(V11~. ,data=dat)
fitted=model$fitted.values





################################   PCA
m=6;
n=10
X=matrix(rnorm(m*n),m,n)*matrix(1*c(rep(1,m*n/2),3*rep((m/2+1):(m),each=n)),m,n,byrow = T) + matrix(10*rep(1:n,m),m,n,byrow = T)
X.t=t(X)  # dimension of n*m
X.c= X%*%(diag(rep(1,n))- 1/n*matrix(1,n,1)%*%matrix(1,1,n))



K.c=(X.c)%*%t(X.c)/(n-1) # n*n
u=eigen(K.c)$vectors[,1]
# u=u-min(u)
u=u/sum(u)

pca_v1=t(X.c)%*%u
ts.plot(t(X.c))
lines(pca_v1,col='red')

ts.plot(t(X))
lines(pca_v2<-t(X)%*%u,col='red')
lines((mean_v=apply(X,2,mean)),col='green')

sum(abs((pca_v2)-10*rep(1:n,1)))

sum(abs(((mean_v=apply(X,2,mean))-10*rep(1:n,1))))





