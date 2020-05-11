CU_convertor = function(raw_file,col_names){
  # This file converts CU-model data file to our target file format
  raw_data=as_tibble(read.csv(raw_file,stringsAsFactors=F))
  raw_data=filter(raw_data, grepl("cum", raw_data$target,fixed=T))
  raw_data_point=filter(raw_data,type=="point")
  raw_data_quantile=filter(raw_data,type=="quantile")
  
  target_data_point=as_tibble(matrix(NA,nrow(raw_data_point),length(col_names))) # target data for point estimate
  colnames(target_data_point)=col_names
  for(i in 1:nrow(target_data_point)){
    target_data_point$forecast_date[i] = raw_data_point$forecast_date[i]
    target_data_point$model_name[i] = strsplit(raw_file,split="/")[[1]][3]
    target_data_point$target_date[i] = raw_data_point$target_end_date[i]
    target_data_point$lookahead[i] = as.Date(target_data_point$target_date[i]) - as.Date(target_data_point$forecast_date[i])
    target_data_point$location_long[i] = raw_data_point$location_name[i]
    target_data_point$prediction_type[i] = raw_data_point$type[i]
    target_data_point$expected_value[i] = raw_data_point$value[i]
    target_data_point$gt_source[i]="gt_jhu"
    ## target_data_quantile
  }
  target_data_quantile=target_data_point# the number of obsevations of point estimation and quantile is same
  target_data_quantile$prediction_type="quantile"
  target_data_quantile$expected_value=NA
  ind.num1=which(col_names=="perc_0.010")
  ind.num2=which(col_names=="perc_0.990")
  target_data_quantile[,ind.num1:ind.num2]=0
  for(i in 1:nrow(target_data_quantile)){
    tem=filter(raw_data_quantile,target_end_date==target_data_quantile$target_date[i],location_name==target_data_quantile$location_long[i])
    if(nrow(tem)>ind.num2-ind.num1+1){tem=tem[1:(ind.num2-ind.num1+1),]}
    tem=tem[order(tem$value),]
    target_data_quantile[i,ind.num1:ind.num2]=as_tibble(matrix(tem$value,1))
  }
  target_data=bind_rows(target_data_point,target_data_quantile)
  
  
  jhu_truth = read.csv("jhu_truth.csv",stringsAsFactors=F)
  colnames(jhu_truth)[13]=as.character("2020-01-22")
  for(i in 14:ncol(jhu_truth)){
    colnames(jhu_truth)[i]=as.character(as.Date(colnames(jhu_truth)[13])+i-13)
  }
  US_states=unique(jhu_truth$Province_State)
  truth=vector("list",length = length(US_states))
  names(truth)=US_states
  for(i in 1:length(US_states)){
    truth[[i]]=filter(jhu_truth,Province_State==US_states[i])[,-c(1:12)]
  }
  
  for(i in 1:nrow(target_data)){ # fill in the ground truth data
    target_data$gt_jhu[i]= sum(truth[target_data$location_long[i]][[1]][target_data$forecast_date[i]])
  } 
  return(target_data)
}
