import numpy as np # linear algebra
import pandas as pd # data processing
from datetime import datetime
import pickle,requests
import matplotlib.pyplot as plt
import seaborn as sns
import time, os, sys
from contextlib import contextmanager
from sklearn.cluster import KMeans

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
        
    def submit(self,predict,tech):
        # make submit file
        submit_file = pd.read_csv(self.home_path + "/input/raw/sample_submission.csv")
        submit_file["scalar_coupling_constant"] = predict
        # save for output/(technic name + datetime + .csv)
        file_name = self.home_path + '/output/submit/' + tech + '_' + datetime.now().strftime("%Y%m%d") + ".csv"
        submit_file.to_csv(file_name, index=False)
        
    def open_parameter(self,file_name):
        f = open(self.home_path + '/input/parameters/' + file_name + '.txt', 'rb')
        list_ = pickle.load(f)
        return list_
        
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
    # 動作未確認
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
