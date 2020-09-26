#!/bin/bash

stage=0
. ./cmd.sh
. ./path.sh
. parse_options.sh

set -e

if [ $stage -le 0 ]; then
 bash local/prepare_data.sh --stage 2
fi

if [ $stage -le 4 ]; then

 path=
 g2p_model=data/local/lm/g2p-model-5
 if [ ! -f $g2p_model ]; then
	 mkdir -p data/local/lm
	 cp $path/g2p-model-5 $g2p_model
 fi

 bash local/prepare_dict.sh --stage 4 data/local/lm data/local/lm data/local/dict_nosp
fi


if [ $stage -le 8 ]; then
 bash utils/prepare_lang.sh data/local/dict_nosp "<UNK>" data/local/lang_tmp_nosp data/lang_nosp
fi


if [ $stage -le 9 ]; then
    bash local/train_lm.sh --stage 1
fi

if [ $stage -le 11 ]; then
  bash local/format_data.sh data/local/lm
fi

if [ $stage -le 12 ]; then
	bash local/catch_mfcc_train.sh
	if [ ! -d data_mfcc/lang ];then
		cp -r data/lang_nosp data_mfcc/lang
	fi
fi

if [ $stage -le 13 ]; then
	echo "cat train-dev-cv ivector"
	bash local/catch_ivector_train.sh --stage 13
fi

if [ $stage -le 13 ]; then
	bash local/chain_run_tdnn.finetune.sh --stage 15
fi
