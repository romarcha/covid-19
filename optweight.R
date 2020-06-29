optweight=function(sig){
  # the input is the variances of all the predition models
  # the output is the optimal weights for each prediction model
  
  m=length(sig) # the number of prediction models
  w=numeric(m)
  for(i in 1:m){
    w[i]=prod(sig[-i])
  }
  optweight=w/sum(w)
  
}