# AESRC2020

track2-scripts

##### 背景
=======

主页: https://www.datatang.com/INTERSPEECH2020

baseline:  https://github.com/R1ckShi/AESRC2020

####  Track2

口音英语语音识别

####  方案简介
=======

base
----
librispeech960: 默认脚本（
mono, tri, LDA+MLLT, SAT, LDA+MLLT+SAT, FMLLR，这里数据量级由小往大；

local/run_cleanup_segmentation.sh：这个清洗挺好

参考baseline，这里选用librispeech/s5/local/chain/run_cnn_tdnn.sh, 网络结构没有变化
）

tuning
---
在librispeech960的基础上，做tuning，脚本见local/run_cnn_tdnn_finetune.sh

LM and decode
---
由于工作，没时间优化，只使用了tri-gram，没有做二遍解码(rnn-rescore)；

使用了scoring-kaldi脚本，在dev上lattice给了inv-acoustic-scale=17，word插入惩罚给0，这里在test上也取了

#### scripts

run.sh: 训练环境

run_test.sh: 测试环境

#### res
=======

| exp/CER(%)/accent| RU   | KR   | US   | PT   | JPN  | UK   | CHN  | IND  | AVE  |
| -------- | -- |---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| this  | 2.65 | 5.24 | 6.78 | 3.91 | 4.50 | 5.38 | 9.07 | 6.04 | 5.46 |


