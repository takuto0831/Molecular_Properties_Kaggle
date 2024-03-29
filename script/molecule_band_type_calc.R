###  分子の結合の有無を調べる ####

####### 0. setting #######
library(sqldf)
library(tidyverse)

structures <- read_csv("~/Desktop/Molecular_kaggle/input/raw/structures.csv")

atom_info <- tibble::data_frame(
  atom = c("H","C","N","O","F"),
  radius = c(0.38,0.77,0.75,0.73, 0.71) # 原子半径
)

structures <- structures %>% 
  left_join(atom_info, by="atom") 

######### 1. 分子結合の存在するテーブルを取得する ##########
# strutures dataを2つ用意
tmp0 <- structures %>% 
  select(molecule_name,atom,atom_index, x, y, z, radius) %>% 
  mutate(flg = if_else(atom == 'H',1,0))

tmp1 <- structures %>% 
  select(molecule_name,atom,atom_index, x, y, z, radius) %>% 
  mutate(flg = if_else(atom == 'H',1,0))

# 分子名で組み合わせ (atom_index_0 < atom_index_1, H-H, F-Fは存在しない削除)
tmp <- sqldf('SELECT 
             a.molecule_name,
             a.atom AS atom_0, 
             a.atom_index AS atom_index_0,
             a.x AS x_0, a.y AS y_0, a.z AS z_0,
             b.atom AS atom_1, 
             b.atom_index AS atom_index_1,
             b.x AS x_1, b.y AS y_1, b.z AS z_1,
             a.radius + b.radius AS inter_distance,
             CASE WHEN a.flg + b.flg = 0 THEN 0 ELSE 1 END AS flg
             FROM tmp0 AS a 
             INNER JOIN tmp1 AS b on a.molecule_name = b.molecule_name
             AND a.atom_index < b.atom_index
             WHERE (a.atom != "H" OR b.atom != "H")
             AND (a.atom != "F" OR b.atom != "F")')

# 削除
rm(tmp0,tmp1,structures); gc()

# 分子結合が存在するデータの抽出 (原子間距離 < 原子半径)
structures_bond <- tmp %>% 
  mutate(distance = sqrt((x_0-x_1)^2 + (y_0-y_1)^2 + (z_0-z_1)^2)) %>%
  filter(distance < inter_distance) %>% 
  # filter(atom_0!="O"|atom_0!="F"|atom_1!="O"|atom_1!="F") %>% 
  select(molecule_name, atom_index_0,atom_index_1, distance, flg) 

# #### 2. 酸素原子について ###
# # 出現回数 1: 二重結合, 出現回数 2: 一重結合
# 
# tmp_oxy <- bind_rows(
#   structures_bond %>% 
#     filter(atom_0 == 'O') %>% 
#     select(molecule_name, atom = atom_0,atom_index = atom_index_0,
#            bond_type,bond_type_flg,bond_idx),
#   structures_bond %>% 
#     filter(atom_1 == 'O') %>% 
#     select(molecule_name, atom = atom_1,atom_index = atom_index_1,
#            bond_type,bond_type_flg,bond_idx)) %>% 
#   arrange(molecule_name) %>% 
#   group_by(molecule_name, atom_index) %>% 
#   mutate(flg = n()) %>% # 各酸素原子の出現回数
#   ungroup() %>% 
#   dplyr::select(bond_idx, flg)
# 
# # 元データに left joinして更新
# structures_bond <- structures_bond %>% 
#   left_join(tmp_oxy, by='bond_idx') %>% 
#   mutate(bond_type = case_when(
#     flg == 1 ~ 2, # 二重結合
#     flg == 2 ~ bond_type, # 一重結合
#     TRUE ~ bond_type), # 不明
#     bond_type_flg = if_else(!is.na(flg),1,bond_type_flg)) %>% 
#   select(-flg)
# 
# rm(tmp_oxy); gc()
# #### 3. 窒素原子について ####
# # 出現回数 1: 三重結合, 出現回数 2: 一重結合+ 二重結合, 出現回数 3: 一重結合
# 
# tmp_nit <- bind_rows(
#   structures_bond %>% 
#     filter(atom_0 == 'N') %>% 
#     select(molecule_name, atom = atom_0,atom_index = atom_index_0,
#            bond_type,bond_type_flg,bond_idx),
#   structures_bond %>% 
#     filter(atom_1 == 'N') %>% 
#     select(molecule_name, atom = atom_1,atom_index = atom_index_1,
#            bond_type,bond_type_flg,bond_idx)) %>% 
#   arrange(molecule_name) %>% 
#   group_by(molecule_name, atom_index) %>% 
#   mutate(flg = n()) %>% # 各酸素原子の出現回数
#   ungroup() %>% 
#   dplyr::select(bond_idx, flg)
# 
# # 終了判定
# structures_bond %>% 
#   group_by(molecule_name) %>% 
#   summarise(count = n(), flg_sum = sum(bond_type_flg)) %>% 
#   ungroup() %>% 
#   filter(count == flg_sum) %>% View
# 
# 
# #structures_bond %>% 
# tmp %>% 
#   mutate(distance = sqrt((x_0-x_1)^2 + (y_0-y_1)^2 + (z_0-z_1)^2)) %>% 
#   filter(distance < inter_distance) %>% 
#   filter(molecule_name == "dsgdb9nsd_007602") %>%
#   View