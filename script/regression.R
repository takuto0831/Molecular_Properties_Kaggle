# library
library(glmnet)
library(tidyverse)

# input
train_ <- read_csv("~/Desktop/Molecular_kaggle/input/preprocess/train.csv")
test_ <- read_csv("~/Desktop/Molecular_kaggle/input/preprocess/test.csv")

# convert data
exp_vars <- train_ %>% 
  select(-c(id,molecule_name,atom_index_0,atom_index_1,type,scalar_coupling_constant)) %>% 
  as.matrix()
target_var <- train_ %>% 
  select(scalar_coupling_constant) %>% 
  as.matrix()
test_vars <- test_ %>% 
  select(-c(id,molecule_name,atom_index_0,atom_index_1,type)) %>% 
  as.matrix()

# Ridge
fitRidge1 <- glmnet(x=exp_vars, y = target_var, family = "gaussian", alpha=0)
fitRidgeCV1 <- cv.glmnet( x=exp_vars, y=target_var, family="gaussian", alpha=0 )
plot(fitRidgeCV1) # plot mse