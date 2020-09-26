# AESRC2020

track2-scripts

#####
# 主页：https://www.datatang.com/INTERSPEECH2020

# baseline:

Data preparation scripts and training pipeline for the Interspeech 2020 Accented English Speech Recognition Challenge (AESRC).

https://github.com/R1ckShi/AESRC2020

####  Track2
口音英语语音识别
使用规则限定的训练数据，训练语音识别模型。提交测试集合上的语音识别结果文本。
注：测试集合中会出现训练集外的口音以验证模型泛化性能。禁止使用包括ROVER在内的模型融合技术，音频训练数据限定为官方提供的共160小时口音英文数据，不允许使用音频数据对应的抄本之外的文本信息进行语言模型的训练。对语音数据的数据增广只能基于限定的数据。

#### scripts

run.sh: 训练环境

run_test.sh: 测试环境