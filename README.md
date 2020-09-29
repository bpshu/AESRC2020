# AESRC2020

track2-scripts

##### 背景

主页: https://www.datatang.com/INTERSPEECH2020

baseline:  https://github.com/R1ckShi/AESRC2020

####  Track2
口音英语语音识别
使用规则限定的训练数据，训练语音识别模型。提交测试集合上的语音识别结果文本。
注：测试集合中会出现训练集外的口音以验证模型泛化性能。禁止使用包括ROVER在内的模型融合技术，音频训练数据限定为官方提供的共160小时口音英文数据，不允许使用音频数据对应的抄本之外的文本信息进行语言模型的训练。对语音数据的数据增广只能基于限定的数据。

####  方案简介

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


#### scripts

run.sh: 训练环境

run_test.sh: 测试环境

#### res

| exp/CER(%)/accent| RU   | KR   | US   | PT   | JPN  | UK   | CHN  | IND  | AVE  |
| -------- | -- |---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| this  | 2.65 | 5.24 | 6.78 | 3.91 | 4.50 | 5.38 | 9.07 | 6.04 | 5.46 |


