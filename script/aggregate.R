# python で実行すれば良い?

aggregate_func <- function(df){
  # not rename column
  not_list0 <- vars(-molecule_name, -atom_index_0)
  not_list1 <- vars(-molecule_name, -atom_index_1)
  # aggregated column
  agg_list <- vars(distance,distance_x,distance_y,distance_z)
  # about atom 0
  tmp0 <- df %>% 
    group_by(molecule_name, atom_index_0) %>%
    summarise_at(agg_list, funs(min, max, mean, sd)) %>% 
    ungroup() %>% 
    rename_at(not_list0,funs(str_c(.,"_0")))
  # about atom1
  tmp1 <- df %>% 
    group_by(molecule_name, atom_index_1) %>%
    summarise_at(agg_list, funs(min, max, mean, sd)) %>% 
    ungroup() %>% 
    rename_at(not_list1,funs(str_c(.,"_1")))
  df_ <- df %>% 
    left_join(tmp0,by=c("molecule_name", "atom_index_0")) %>% 
    left_join(tmp1,by=c("molecule_name", "atom_index_1"))
  return(df_)
}

# get dummies function
dummy_func <- function(df){
  tmp <- df %>% 
    mutate(type = factor(type)) %>% 
    makedummies(basal_level = TRUE, col ="type")
  return(bind_cols(df,tmp))
}

#################### execute func (train and test data from python) #####################
# merge data
train_test <- bind_rows(train,test)
rm(train,test); gc()

# aggregate data 
train_test_ <- 
  train_test %>% 
  aggregate_func()
  # dummy_func()