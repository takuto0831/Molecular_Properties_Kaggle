import numpy as np # linear algebra
import pandas as pd # data processing
import lightgbm as lgb
import xgboost as xgb
from sklearn.metrics import mean_squared_error

### model list ###
# LightGBM
# Xgboost

def GradientBoosting(algorithm,param_set,train,test,features,target,folds):
    feature_importance_df = pd.DataFrame()
    ## predict data box
    validation_pred = np.zeros(train.shape[0])
    test_pred = np.zeros(test.shape[0])
    ## remove inf
    train = train.replace([np.inf, -np.inf], np.nan) # inf 処理
    test = test.replace([np.inf, -np.inf], np.nan) # inf 処理
    # 分子 typeを考慮して, データを分割する (分類モデル or kfoldの場合も普通に使える)
    for fold_, (trn_idx, val_idx) in enumerate(folds.split(train,train['type'].values)):
        print("fold n°{}".format(fold_+1))
        # make model
        validation_pred, test_pred, fold_importance_df \
        = algorithm(train,test,trn_idx,val_idx,features,target,param_set,folds,fold_,validation_pred,test_pred)
        # concat importance
        feature_importance_df = pd.concat([feature_importance_df, fold_importance_df], axis=0)
    return validation_pred, test_pred, feature_importance_df
    
def Lightgbm(train,test,trn_idx,val_idx,features,target,param_set,folds,fold_,validation_pred,test_pred):
    # data set
    trn_data = lgb.Dataset(train.iloc[trn_idx][features], label=target.iloc[trn_idx])
    val_data = lgb.Dataset(train.iloc[val_idx][features], label=target.iloc[val_idx])
    # model
    model = lgb.train(param_set, trn_data, num_boost_round=10000, valid_sets = [trn_data, val_data],
                      verbose_eval=100, early_stopping_rounds=200)
    # importance 
    fold_importance_df = pd.DataFrame({'feature': features, 
                                       'importance': model.feature_importance(),
                                       'fold': fold_ + 1})

    # predicting validation data and predicting data
    validation_pred[val_idx] = model.predict(train.iloc[val_idx][features], num_iteration=model.best_iteration)
    test_pred += model.predict(test[features], num_iteration=model.best_iteration) / folds.n_splits
    return validation_pred, test_pred, fold_importance_df
