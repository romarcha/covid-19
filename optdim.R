optdim = function(l,max.row=6){
  # this returns optimal dimension of a graph to arrange the subgraphs, given the number of subgraphs. 
  # max.row sets the maximum rows/columns of the graph
  m=outer(1:max.row,1:max.row,"*")
  if(sum(which(diag(m)==l))>0){
    return(c(sqrt(l),sqrt(l)))
  }
  cand=which(m>=l)
  d=1
  for(i in 1:length(cand)){
    a=cand[i]%%max.row
    if(a==0){a=max.row}
    b=ceiling(cand[i]/max.row)
   if(abs(a-b)<= d){
     r.ind=a
     c.ind=b
     break
   }
  }
  return(c(r.ind,c.ind))
}