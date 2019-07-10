import numpy as np # linear algebra
import pandas as pd # data processing
from datetime import datetime
import pickle,requests
import matplotlib.pyplot as plt
import seaborn as sns
import time, os, sys
from contextlib import contextmanager
from sklearn.cluster import KMeans
from sklearn.metrics import mean_squared_error, mean_absolute_error

class Process:
    def __init__(self):
        # home path
        self.home_path = os.path.expanduser("~") + '/Desktop/Molecular_kaggle'

    def read_data(self):
        #Loading Train and Test Data
        train = pd.read_csv(self.home_path + '/input/preprocess/train.csv')
        test = pd.read_csv(self.home_path + '/input/preprocess/test.csv')
        features = pd.read_csv(self.home_path + '/input/preprocess/features.csv')
        # check data frame
        print("{} observations and {} features in train set.".format(train.shape[0],train.shape[1]))
        print("{} observations and {} features in test set.".format(test.shape[0],test.shape[1]))
        print("{} observations and {} features in features set.".format(features.shape[0],features.shape[1]))
        features = features["feature"].tolist() # features list
        return train, test, features
        
    def submit(self,submit_file,tech):
        # save for output/(technic name + datetime + .csv)
        file_name = self.home_path + '/output/submit/' + tech + '_' + datetime.now().strftime("%Y%m%d") + ".csv"
        submit_file.to_csv(file_name, index=False)
        
    def open_parameter(self,file_name):
        f = open(self.home_path + '/input/parameters/' + file_name + '.txt', 'rb')
        list_ = pickle.load(f)
        return list_
        
    # 動作未確認 !!!!
    def display_importances(self,importance_df,title,file_name = None):
        cols = (importance_df[["feature", "importance"]]
                .groupby("feature")
                .mean()
                .sort_values(by="importance", ascending=False)[:200].index)
        best_features = importance_df.loc[importance_df.feature.isin(cols)]
        plt.figure(figsize=(14,50))
        sns.barplot(x="importance",y="feature",
                    data=best_features.sort_values(by="importance",ascending=False))
        plt.title(title + 'Features (avg over folds)')
        plt.tight_layout()
        # save or not
        if file_name is not None: 
            plt.savefig(self.home_path + '/output/image/' + file_name)
    # 動作未確認 !!!!
    def extract_best_features(self,importance_df,num,file_name = None):
        cols = (importance_df[["feature", "importance"]]
                .groupby("feature")
                .mean()
                .sort_values(by="importance", ascending=False)
                .reset_index())
        # save or not
        if file_name is not None: 
            feather.write_dataframe(cols, self.home_path + '/input/features/' + file_name + '.feather')
        return cols[:num]["feature"].tolist()
        
# モデルの実行を補助する関数
class Assistance:
    def __init__(self):
        self.target = 'scalar_coupling_constant'
        self.idx = 'id'
    def split_execute_model(self,split_value, train, test, model, model_arg):
        # setting
        submit_df = pd.DataFrame()
        log_mae = []
        # split list
        split_list = train[split_value].unique().copy()
        # model execute by split list
        for list_ in split_list:
            print("~~~~~~~~~ type name:", list_, " ~~~~~~~~~")
            # update model_arg dictionary
            train_ = train[train[split_value] == list_].copy()
            test_ = test[test[split_value] == list_].copy()
            model_arg.update(train = train_, test = test_)
            # model
            val_pred, test_pred, importance = model(**model_arg)
            # concat data and validation value
            log_mae.append(np.log(mean_absolute_error(train_[self.target].values, val_pred)))
            test_[self.target] = test_pred        
            submit_df = pd.concat([submit_df,test_[[self.idx,self.target]]], axis=0)
        # sort by id
        submit_df = submit_df.sort_values(self.idx)
        return log_mae, submit_df
  
# other 
def line(text):
    line_notify_token = '07tI1nvYaAtGaLdsCaxKZxkboOU0OsvLregXqodN2ZV' #先程発行したコードを貼ります
    line_notify_api = 'https://notify-api.line.me/api/notify'
    message = '\n' + text
    # 変数messageに文字列をいれて送信します トークン名の隣に文字が来てしまうので最初に改行しました
    payload = {'message': message}
    headers = {'Authorization': 'Bearer ' + line_notify_token}
    line_notify = requests.post(line_notify_api, data=payload, headers=headers)
@contextmanager
def timer(title):
    start = time.time()
    yield
    end = time.time()
    line("{} - done in {:.0f}s".format(title, end-start))
