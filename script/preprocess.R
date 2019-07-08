# library
library(tidyverse)
library(CatEncoders)
library(makedummies)
library(data.table)
library(tictoc)
library(janitor)
# library(feather)

# input
train <- read_csv("~/Desktop/Molecular_kaggle/input/raw/train.csv")
test <- read_csv("~/Desktop/Molecular_kaggle/input/raw/test.csv")
structures <- read_csv("~/Desktop/Molecular_kaggle/input/raw/structures.csv")

# add sub information (原子量とか?)
atom_info <- dplyr::data_frame(
  atom = c("H","C","N","O","F"),
  radius = c(0.38,0.77,0.75,0.73, 0.71),
  electro_num = c(1, 4, 3, 2, 1),
  electro_nega = c(2.2, 2.55, 3.04, 3.44, 3.98)
)
structures <- structures %>% 
  left_join(atom_info, by="atom")

# func
preprocess <- function(df){
  ### 1, 原子間の関係性 ###
  list_ <- vars(x,y,z,radius,electro_num,electro_nega)
  df_ <- df %>% 
    # 結合情報の数値化
    mutate(via_number = parse_number(type),
           type_number = as.integer(factor(type))) %>% 
    # 結合原子情報の集約
    left_join(structures %>% 
                rename_at(list_, funs(str_c(.,"0"))) %>% 
                select(-atom), 
              by=c("molecule_name", "atom_index_0" = "atom_index")) %>%
    left_join(structures %>% 
                rename_at(list_, funs(str_c(.,"1"))) %>% 
                select(-atom), 
              by=c("molecule_name", "atom_index_1" = "atom_index")) %>%
    # 原子間距離(3d, x, y, z)
    mutate(distance = sqrt((x0-x1)^2 + (y0-y1)^2 + (z0-z1)^2),
           distance_x = sqrt((x0-x1)^2),
           distance_y = sqrt((y0-y1)^2),
           distance_z = sqrt((z0-z1)^2)) %>% 
    mutate(bond_exist = if_else(distance < (radius0 + radius1), 1, 0), # 結合が存在する?
           electro_num_diff = sqrt((electro_num0-electro_num1)^2),
           electro_nega_diff = sqrt((electro_nega0-electro_nega1)^2))
    
  ### 2. 各原子の情報 ###
  #df_ <- df_ %>% 
  #  gr
  
  ### ?. 不要な情報削除 ###
  #df_ <- df %>% 
  #  select(-c(x0,y0,z0,x1,y1,z1,radius0,radius1,electro_nega0,electro_nega1,
  #            electro_num0, electro_num1)) 
  return(df_)
}
# get dummies function
dummy_func <- function(df){
  tmp <- df %>% 
    mutate(type = factor(type)) %>% 
    makedummies(basal_level = TRUE, col ="type")
  return(bind_cols(df,tmp))
}
### お試し####
tmp <- train_test_ %>% 
  head(100) %>% 
  # about atom_0
  group_by(molecule_name, atom_index_0) %>% 
  mutate(inv_dist_0 = 1/sum(1/distance^3),
         inv_dist_0_R = 1/sum(1/((distance-radius0-radius1)^2)),
         inv_dist_0_E = 1/sum(1/((distance*(0.5*electro_nega0+0.5*electro_nega1))^2))) %>% 
  ungroup() %>% 
  # about atom_1
  group_by(molecule_name, atom_index_1) %>% 
  mutate(inv_dist_1 = 1/sum(1/distance^3),
         inv_dist_1_R = 1/sum(1/(distance-radius0-radius1)^2),
         inv_dist_1_E = 1/sum(1/((distance*(0.5*electro_nega0+0.5*electro_nega1))^2))) %>% 
  ungroup() %>% 
  # about atom_0 and atom_1
  mutate(inv_dist_PR = (inv_dist_0_R*inv_dist_1_R)/(inv_dist_0_R+inv_dist_1_R),
         inv_dist_PE = (inv_dist_0_E*inv_dist_1_E)/(inv_dist_0_E+inv_dist_1_E))

#################### execute func #####################
# merge
train_test <- bind_rows(train,test)
rm(train,test); gc()

# aggregate
train_test_ <- 
  preprocess(train_test)
  # dummy_func()
# extract features columns
features <- train_ %>% 
  # 特徴量として扱わないカラム
  select(-c(id,molecule_name,atom_index_0,atom_index_1,type,scalar_coupling_constant)) %>% 
  colnames() %>% 
  data.frame(feature = .)
# save to file
write_csv(train_, "~/Desktop/Molecular_kaggle/input/preprocess/train.csv")
write_csv(test_, "~/Desktop/Molecular_kaggle/input/preprocess/test.csv")
write_csv(features, "~/Desktop/Molecular_kaggle/input/preprocess/features.csv")
