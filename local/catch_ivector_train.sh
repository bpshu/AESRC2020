#!/bin/bash

stage=13
. ./cmd.sh
. ./path.sh
. parse_options.sh
nj=100
ivector_extractor=/data/002.data.beiping.shu/kaldi/egs/librispeech/s5/exp/nnet3_cleaned/extractor

if [ $stage -le 13 ]; then
	for data in train dev; do
	   (nj_=nj
	   spk_num=`cat data_mfcc/${data}_hires/spk2utt | wc -l`
	   if [ $spk_num -le $nj ];then
		   nj_=$spk_num
	   fi
	   steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj ${nj_} \
	   data_mfcc/${data}_hires $ivector_extractor \
	   exp/ivectors_${data}_hires || exit 1;
	   )&
	done
fi

if [ $stage -le 14 ]; then
         nj=20
         for x in US UK IND CHN JPN PT RU KR; do
                 (nj_=$nj
                 spk_num=`cat data_mfcc/cv_hires/${x}/spk2utt | wc -l`
                 if [ $spk_num -le $nj ];then
                         nj_=$spk_num;
                 fi
		 steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj ${nj_} \
			 data_mfcc/cv_hires/${x} $ivector_extractor \
			 exp/ivectors_cv_hires/${x} || exit 1;
		 )&
         done
	 wait
 fi
