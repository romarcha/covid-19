# EDA plots
# The data is us_wide_log and us_wide
single_pred=us_wide[,-c(1,ncol(us_wide))]
single_pred <- (single_pred-single_pred$gt) %>% dplyr::select(.,-gt) %>% pivot_longer(everything(),names_to ="Models",values_to = "AE" ) %>% mutate(.,AE=abs(AE))

T=group_by(single_pred,Models)
st=summarise(T,min=min(AE),stq=quantile(AE,0.25),med=median(AE),mean=mean(AE),rdq=quantile(AE,0.75),max=max(AE))
st[,-1]=round(st[,-1],digits = 0)
latex(st,rowname=NULL,numeric.dollar=F)


pl=ggplot(single_pred)+ geom_histogram(aes(AE),fill='lightblue') +facet_wrap(vars(Models),nrow = 4,ncol=4)
ggsave(filename = "../Results/BLR/US_single_AE.pdf",plot = pl,width = 10, height = 10)



