# library
library(tidyverse)
library(CatEncoders)
library(makedummies)
library(feather)

# input
train <- read_csv("~/Desktop/Molecular_kaggle/input/raw/train.csv")
test <- read_csv("~/Desktop/Molecular_kaggle/input/raw/test.csv")
structures <- read_csv("~/Desktop/Molecular_kaggle/input/raw/structures.csv")

# add sub information
atom_info <- dplyr::data_frame(
  atom = c("H","C","N","O","F"),
  radius = c(0.38,0.77,0.75,0.73, 0.71),
  electro_negative = c(2.2, 2.55, 3.04, 3.44, 3.98)
)
structures <- structures %>% 
  left_join(atom_info, by="atom")

# func
preprocess <- function(df){
  df_ <- df %>% 
    mutate(via_number = parse_number(type)) %>% 
    left_join(structures %>% 
                rename_at(vars(x,y,z,radius,electro_negative), funs(str_c(.,"0"))) %>% 
                select(-atom), 
              by=c("molecule_name", "atom_index_0" = "atom_index")) %>%
    left_join(structures %>% 
                rename_at(vars(x,y,z,radius,electro_negative), funs(str_c(.,"1"))) %>% 
                select(-atom), 
              by=c("molecule_name", "atom_index_1" = "atom_index")) %>%
    # 原子間距離(3d, x, y, z)
    mutate(distance = sqrt((x0-x1)^2 + (y0-y1)^2 + (z0-z1)^2),
           distance_x = sqrt((x0-x1)^2),
           distance_y = sqrt((y0-y1)^2),
           distance_z = sqrt((z0-z1)^2)) %>% 
    #結合が存在するか, 電位差
    mutate(bond_exist = if_else(distance < (radius0 + radius1), 1, 0),
           electro_diff = sqrt((electro_negative0-electro_negative1)^2)) %>% 
    # 不要な情報削除
    select(-c(x0,y0,z0,x1,y1,z1,radius0,radius1,electro_negative0,electro_negative1)) 
  return(df_)
}
# get dummies function
dummy_func <- function(df){
  tmp <- df %>% 
    mutate(type = factor(type)) %>% 
    makedummies(basal_level = TRUE, col ="type")
  return(bind_cols(df,tmp))
}

# execute func
train_ <- preprocess(train) %>% 
  dummy_func()
test_ <- preprocess(test) %>% 
  dummy_func()

features <- train_ %>% 
  # 特徴量として扱わないカラム
  select(-c(id,molecule_name,atom_index_0,atom_index_1,type,scalar_coupling_constant)) %>% 
  colnames() %>% 
  data.frame(feature = .)
# save to file
write_csv(train_, "~/Desktop/Molecular_kaggle/input/preprocess/train.csv")
write_csv(test_, "~/Desktop/Molecular_kaggle/input/preprocess/test.csv")
write_csv(features, "~/Desktop/Molecular_kaggle/input/preprocess/features.csv")
