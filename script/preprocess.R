################# setting ###################

# library
library(tidyverse)
library(CatEncoders)
library(makedummies)
library(data.table)
library(tictoc)
library(janitor)
library(skimr)

# input
train <- read_csv("~/Desktop/Molecular_kaggle/input/raw/train.csv")
test <- read_csv("~/Desktop/Molecular_kaggle/input/raw/test.csv")
structures <- read_csv("~/Desktop/Molecular_kaggle/input/raw/structures.csv")

# add sub information (原子量とか?)
atom_info <- tibble::data_frame(
  atom = c("H","C","N","O","F"),
  radius = c(0.38,0.77,0.75,0.73, 0.71), # 原子半径
  # radius = c(1.20, 1.70, 1.55, 1.52, 1.47), # ファンデルワールス半径
  # electro_num = c(1, 4, 3, 2, 1), # 活用あるか?
  electro_nega = c(2.2, 2.55, 3.04, 3.44, 3.98)
)
structures <- structures %>% 
  left_join(atom_info, by="atom")

######################## function ########################
preprocess_func <- function(df){
  ### 1, 原子間の関係性 ###
  list_ <- vars(x,y,z,atom,radius,electro_nega)
  df_ <- df %>% 
    # 結合情報の数値化, label encoding for 'type'
    mutate(via_number = parse_number(type),
           type_number = as.integer(factor(type))) %>% 
    # 結合原子情報の集約
    left_join(structures %>% 
                rename_at(list_, funs(str_c(.,"_0"))), 
              by=c("molecule_name", "atom_index_0" = "atom_index")) %>%
    left_join(structures %>% 
                rename_at(list_, funs(str_c(.,"_1"))), 
              by=c("molecule_name", "atom_index_1" = "atom_index")) %>%
    # 原子間距離(3d, x, y, z)
    mutate(distance = sqrt((x_0-x_1)^2 + (y_0-y_1)^2 + (z_0-z_1)^2),
           distance_x = sqrt((x_0-x_1)^2),
           distance_y = sqrt((y_0-y_1)^2),
           distance_z = sqrt((z_0-z_1)^2)) %>%
    # 何の命名?? (from giba kernel)
    # mutate(coulomb = 1/distance,
    #        vander = 1/distance^3,
    #        yukawa = exp(-distance)) %>% 
    #mutate(bond_exist = if_else(distance < (radius_0 + radius_1), 1, 0), # typeに情報含まれている
    #       electro_num_diff = sqrt((electro_num_0-electro_num_1)^2), # 
    #       electro_nega_diff = abs(electro_nega_0-electro_nega_1))
  rm(df,structures); gc()
  ### 2. 各原子の情報 ###
  # about atom_0
  # df_ <- df_ %>% 
  #   group_by(molecule_name, atom_index_0) %>% 
  #   mutate(couple_number_0 = n_unique(atom_index_1),
  #          type_link_0 = str_c(type,collapse=" "),
  #          inv_dist_0 = 1/sum(1/distance^3),
  #          inv_dist_0_R = 1/sum(1/((distance-radius_0-radius_1)^2)),
  #          inv_dist_0_E = 1/sum(1/((distance*(0.5*electro_nega_0+0.5*electro_nega_1))^2))) %>% 
  #   ungroup() %>% 
  #   # about atom_1
  #   group_by(molecule_name, atom_index_1) %>% 
  #   mutate(couple_number_1 = n_unique(atom_index_0),
  #          type_link_1 = str_c(type,collapse=" "),
  #          inv_dist_1 = 1/sum(1/distance^3),
  #          inv_dist_1_R = 1/sum(1/(distance-radius_0-radius_1)^2),
  #          inv_dist_1_E = 1/sum(1/((distance*(0.5*electro_nega_0+0.5*electro_nega_1))^2))) %>% 
  #   ungroup()
  ### 3. 複合情報 ###
  # 前処理1 (type_link to label encoding and spread table)
  # df_ <- df_ %>% 
  #   gather(key = type_link_name, value=type_link, type_link_0, type_link_1) %>% 
  #   mutate(type_link_number = as.integer(factor(type_link))) %>% 
  #   select(-type_link) %>% 
  #   tidyr::spread(key = type_link_name, value=type_link_number) %>% 
  #   # about molecule and atom (解釈よくわからん)
  #   group_by(molecule_name, atom_index_0, atom_1) %>%
  #   mutate(distance_atom_num_0 = sum(distance)/n()) %>% 
  #   ungroup() %>% 
  #   group_by(molecule_name, atom_index_1, atom_1) %>%
  #   mutate(distance_atom_num_1 = sum(distance)/n()) %>% 
  #   ungroup() %>% 
  #   # about type_link_0
  #   group_by(type_link_0) %>% 
  #   mutate(type_link_mean_0 = mean(inv_dist_0) - inv_dist_0) %>% 
  #   ungroup() %>% 
  #   # about type_link_1
  #   group_by(type_link_1) %>% 
  #   mutate(type_link_mean_1 = mean(inv_dist_1) - inv_dist_0) %>% 
  #   ungroup() %>% 
  #   # about type_link_0 and type_link_1
  #   group_by(type_link_0, type_link_1) %>% 
  #   mutate(type_ling_count = n()) %>% 
  #   ungroup() %>% 
  #   # about all
  #   mutate(inv_dist_PR = (inv_dist_0_R*inv_dist_1_R)/(inv_dist_0_R+inv_dist_1_R),
  #          inv_dist_PE = (inv_dist_0_E*inv_dist_1_E)/(inv_dist_0_E+inv_dist_1_E)) 
  ## 4. 不要カラムの削除
  df_ <- df_ %>% 
    select()
  return(df_)
}
# aggregate function
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
#################### execute func #####################
# merge data
train_test <- bind_rows(train,test)
rm(train,test); gc()

# aggregate data 
train_test_ <- 
  train_test %>% 
  # head(100000) %>% 
  preprocess_func() %>% 
  aggregate_func()
# dummy_func()

# extract features columns
features <- train_test_ %>% 
  # 特徴量として扱わないカラム
  select(-c(id,molecule_name,atom_index_0,atom_index_1,type,scalar_coupling_constant,
            atom_0,atom_1,x_0,y_0,z_0,x_1,y_1,z_1,radius_0,radius_1,electro_nega_0,
            electro_nega_1,type_number)) %>% 
  colnames() %>% 
  data.frame(feature = .)

# split train data and test data 
train <- train_test_ %>% filter(!is.na(scalar_coupling_constant))
test <- train_test_ %>% filter(is.na(scalar_coupling_constant))
rm(train_test_); gc()

# save to file
write_csv(train, "~/Desktop/Molecular_kaggle/input/preprocess/train.csv")
write_csv(test, "~/Desktop/Molecular_kaggle/input/preprocess/test.csv")
write_csv(features, "~/Desktop/Molecular_kaggle/input/preprocess/features.csv")


######################## 考察用 ##########################
#train <- read_csv("~/Desktop/Molecular_kaggle/input/preprocess/train.csv")
#test <- read_csv("~/Desktop/Molecular_kaggle/input/preprocess/test.csv")
#features <- read_csv("~/Desktop/Molecular_kaggle/input/preprocess/features.csv")
