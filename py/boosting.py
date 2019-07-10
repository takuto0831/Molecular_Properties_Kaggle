import numpy as np # linear algebra
import pandas as pd # data processing
import lightgbm as lgb
# import xgboost as xgb
from functools import partial
import optuna, os
from sklearn.metrics import mean_squared_error, mean_absolute_error
from sklearn.model_selection import StratifiedKFold, KFold, GroupKFold

### model list ###
# LightGBM

class LightGBM:
    def __init__(self):
        ### important value name
        self.target = 'scalar_coupling_constant'
        self.group = 'molecule_name' # for GroupKFold
  
        ### home path
        self.home_path = os.path.expanduser("~") + '/Desktop/Molecular_kaggle'
        ### validation setting
        #self.fold = StratifiedKFold(n_splits=4, shuffle=True, random_state=831)
        self.fold = GroupKFold(n_splits=5) # shuffleもある

    def Model(self,train,trn_index,val_index,features,param={}):
        # data set
        trn_data = lgb.Dataset(train.iloc[trn_index][features], label=train.iloc[trn_index][self.target])
        val_data = lgb.Dataset(train.iloc[val_index][features], label=train.iloc[val_index][self.target])
        # model
        model = lgb.train(param, 
                          trn_data, 
                          # categorical_feature = category_features,
                          num_boost_round= 2000, 
                          valid_sets = [trn_data, val_data],
                          verbose_eval= 200, 
                          early_stopping_rounds= 200)
        return model
        
    def lightgbm(self,train,test,features,param={}, name = "Lightgbm Regression"):
        # 実行環境の確認
        print('validation method:', self.fold, 'groups value:', self.group)
        # バリデーション,テスト予測,特徴量の寄与度格納用
        val_pred = np.zeros(train.shape[0])
        test_pred = np.zeros(test.shape[0])
        feature_importance = pd.DataFrame()
        # モデル実行 (self.groupを元に, バリデーションを決定する)
        for i,(trn_index, val_index) in enumerate(self.fold.split(train,groups=train[self.group].values)):
            print("fold n°{}".format(i+1))
            # model execute
            model = self.Model(train,trn_index,val_index,features,param)
            # model importance 
            fold_importance = pd.DataFrame({'feature': features, 
                                            'importance': model.feature_importance(),
                                            'fold': i + 1})
            feature_importance = pd.concat([feature_importance, fold_importance], axis=0)
            
            # predicting validation data and predicting data
            val_pred[val_index] = model.predict(train.iloc[val_index][features], num_iteration=model.best_iteration)
            test_pred += model.predict(test[features], num_iteration=model.best_iteration) / self.fold.n_splits
        return val_pred, test_pred, fold_importance
    # 動作未確認!!
    def tuning(self,train,features,trial):
        # score
        score = []
        # tuning parameters
        param = {
            'objective':'regression',
            'metric': 'rmse',
            'verbosity': -1, # 計算結果の表示有無
            'max_depth' : -1, # 決定木の深さ, デフォルト値
            'boosting_type': trial.suggest_categorical('boosting', ['gbdt', 'dart', 'goss']),
            'num_leaves': trial.suggest_int('num_leaves',5, 1000), # 決定木の複雑度
            'learning_rate': trial.suggest_loguniform('learning_rate', 1e-8, 1.0), # 重み係数
            # 'min_data_in_leaf: # 決定木ノードの最小データ数
        }
        # boosting type parameters  
        if param['boosting_type'] == 'dart':
            param['drop_rate'] = trial.suggest_loguniform('drop_rate', 1e-8, 1.0)
            param['skip_drop'] = trial.suggest_loguniform('skip_drop', 1e-8, 1.0)
        if param['boosting_type'] == 'goss':
            param['top_rate'] = trial.suggest_uniform('top_rate', 0.0, 1.0)
            param['other_rate'] = trial.suggest_uniform('other_rate', 0.0, 1.0 - param['top_rate'])
        
        for i,(trn_index, val_index) in enumerate(self.fold.split(train,train[self.group].values)):
            print("fold n°{}".format(i+1))
            # model execute
            model = self.Model(train,trn_index,val_index,features,param)
            # validation predict
            pred = model.predict(train.iloc[val_index][features],num_iteration = model.best_iteration)
            pred = np.round(pred).astype(int)
            # score
            score.append(np.sqrt(mean_squared_error(train.iloc[val_index][self.target], pred))) #RMSE
            score.append(mean_absolute_error(train.iloc[val_index][self.target], pred)) #MAE
        return np.mean(score)
 
