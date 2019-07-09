# Molecular_Properties_Kaggle

原子の磁気相互作用を予測するアルゴリズムを発展させる. MRIのような分子組成を可視化するような技術に近い. Nuclear Magnetic Resonance (NMR: 核磁気共鳴)はタンパク質や分子の組織, ダイナミクスを理解する技術である?

NMR情報として, スカラーカップリングを用いる. 核スピンの双極子相互作用は数k~ 数十kHzの大きさをもつ双極子カップリングと,数十kHzの大きさをもつスカラーカップリングからなる. 溶液中では, 双極子カップリングはランダムな分子運動によって平均化され0となり,スカラーカップリングのみが残る. スカラーカップリングの大きさはシグナルの分裂幅から求められ, NOE(核 Overhauser 効果)と共に分子構造に関する情報を持っている.

NMRを使用して, 分子の構造とダイナミクスを理解することは, いわゆるスカラーカップリングを正確に予測する能力に依存する. この相互作用の強さは分子の立体構造を構成する介在電子と化学結合に依存します. 量子力学からの最先端の方法を用いて, 入力として三次元分子構造のみを与え, スカラーカップリング定数を正確に計算することが可能である. しかしながら, これらの量子力学計算は非常に高価である.

これらの相互作用を予測するための速くて信頼性の高い方法は薬化学者がより速くそしてより安価に構造的洞察を得ることを可能にし, 科学者が分子の3D化学構造がその性質と挙動にどのように影響するかを理解することを可能にする. 

## Evaluation

Log of Mean Absolute Errorを使用する. T:スカラーカップリング種類(type), n_t: tの観測数, y_t: スカラーカップリング定数

<div align="center">
<img src="https://latex.codecogs.com/gif.latex?score&space;=&space;\frac{1}{T}\sum_{t=1}^T&space;\left(\frac{1}{n_t}&space;\sum_{i=1}^{n_t}&space;|y_i&space;-&space;\hat{y}_i|&space;\right)" title="score = \frac{1}{T}\sum_{t=1}^T \log \left(\frac{1}{n_t} \sum_{i=1}^{n_t} |y_i - \hat{y}_i| \right)" />
</div>


## about target 

二つの原子が与えられた時の, スカラーカップリング定数を予測する. このコンペティションでは各分子の全ての原子ペアを予測するのではなく, 訓練データとテストデータに明示的にリストされているペアを予測するだけである. 

## Referrence

- [NMR Facility Coupling constants](http://sopnmr.ucsd.edu/coupling.htm)
- [NMRの基礎知識, 原理編](https://www.chem-station.com/blog/2018/01/nmr.html)
- [NMRの測定, 解析編](https://www.chem-station.com/blog/2018/01/nmr2.html)
- [核磁気共鳴の基礎, 伊藤順吉(1946)](https://www.jstage.jst.go.jp/article/kobunshi1952/6/5/6_5_238/_pdf/-char/ja)
- [核磁気共鳴分析, 三井化学分析センター](https://www.mcanac.co.jp/service/detail/1002.html?c1n=分析機器別分類&c1s=machine&c2n=ＮＭＲ分析&c2s=01)
- [スカラーカップリング定数](https://www.chem.wisc.edu/areas/reich/nmr/05-hmr-03-jcoupl.htm)
- [角運動量](http://w3e.kanazawa-it.ac.jp/math/physics/category/mechanics/motion/angular_momentum/henkan-tex.cgi?target=/math/physics/category/mechanics/motion/angular_momentum/angular_momentum.html)


## Directory

```

├── README.md
├── input
│   ├── data_definition.xlsx
│   └── raw
│       ├── dipole_moments.csv
│       ├── magnetic_shielding_tensors.csv
│       ├── mulliken_charges.csv
│       ├── potential_energy.csv
│       ├── sample_submission.csv
│       ├── scalar_coupling_contributions.csv
│       ├── structures.csv
│       ├── structures.zip
│       ├── test.csv
│       └── train.csv
├── jn
│   └── EDA.ipynb
├── output
│   └── submit
│       └── example_mean_base.csv
└── rmd
    └── EDA.Rmd

```
