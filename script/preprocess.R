# library
library(tidyverse)
# input
train <- read_csv("~/Desktop/Molecular_kaggle/input/raw/train.csv")
test <- read_csv("~/Desktop/Molecular_kaggle/input/raw/test.csv")
structures <- read_csv("~/Desktop/Molecular_kaggle/input/raw/structures.csv")

# add sub information
atom_info <- dplyr::data_frame(
  atom = c("H","C","N","O","F"),
  atom_radius = c(0.38,0.77,0.75,0.73, 0.71),
  elctro_negative = c(2.2, 2.55, 3.04, 3.44, 3.98)
)

structures <- structures %>% 
  left_join(atom_info, by="atom")

# train and test data
# test_ <- test %>% 

train_ <- train %>% 
  mutate(via_number = parse_number(type)) %>% 
  left_join(structures %>% 
              rename_at(vars(x,y,z), funs(str_c(.,"0"))) %>% 
              select(-atom), 
            by=c("molecule_name", "atom_index_0" = "atom_index")) %>%
  left_join(structures %>% 
              rename_at(vars(x,y,z), funs(str_c(.,"1"))) %>% 
              select(-atom), 
            by=c("molecule_name", "atom_index_1" = "atom_index")) %>%
  mutate(distance = sqrt((x0-x1)^2 + (y0-y1)^2 + (z0-z1)^2),
         distance_x = sqrt((x0-x1)^2),
         distance_y = sqrt((y0-y1)^2),
         distance_z = sqrt((z0-z1)^2)) %>% 
  select(-c(x0,y0,z0,x1,y1,z1)) # 座標の情報は削除



