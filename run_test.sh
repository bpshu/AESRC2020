#!/usr/bin/env bash

#Copyright 2019-2020 chaoyi.wang
#          2019-2020 beiping.shu

set -e
#
stage=21
nj=200

. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh  # e.g. this parses the above options
                            # if supplied.

mfccdir=mfcc
data_mfcc=data_mfcc


if [ $stage -le 21 ];then
	bash  local/test_data_prepare.sh
fi

if [ $stage -le 22 ];then

	for x in test; do
		  (nj_=$nj
		  spk_num=`cat $data_mfcc/${x}_hires/spk2utt | wc -l`
		  if [ $spk_num -le $nj_ ];then
		    nj_=$spk_num
		  fi
		  steps/make_mfcc.sh --cmd "$train_cmd" --nj ${nj_}  --mfcc-config conf/mfcc_hires.conf ${data_mfcc}/${x}_hires exp/make_mfcc_hires/${x} ${mfccdir} || exit 1;
		  steps/compute_cmvn_stats.sh ${data_mfcc}/${x}_hires exp/make_mfcc/${x}_hires $mfccdir || exit 1;
		  utils/fix_data_dir.sh $data_mfcc/${x}_hires || exit 1;
		  )&
	done
	wait
fi


ivector_extractor=/data/002.data.beiping.shu/kaldi/egs/librispeech/s5/exp/nnet3_cleaned/extractor

if [ $stage -le 23 ];then
	for data in test; do
		nj_=$nj
		spk_num=`cat $data_mfcc/${data}_hires/spk2utt | wc -l`
		if [ $spk_num -le $nj_ ];then
			 nj_=$spk_num
		fi
	   steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj ${nj_} \
		   data/${data}_hires $ivector_extractor \
		   exp/ivectors_${data}_hires || exit 1;
	done
fi
 
dir=exp/chain_cnn_tuning

ivector_dir=exp/ivectors_test_hires
test_ivec_opt="--online-ivector-dir ${ivector_dir}"

symtab=exp/chain_cnn_tuning/graph/words.txt
hyp_filtering_cmd=local/wer_hyp_filter

if [ $stage -le 24 ];then
	steps/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 \
	--skip_scoring "true" \
	 --scoring-opts "--min-lmwt 1" \
	 --nj 200 --cmd "$decode_cmd" $test_ivec_opt \
	 $dir/graph data_mfcc/test_hires $dir/decode_test || exit 1;
fi

if [ $stage -le 25 ];then
	 $train_cmd $dir/decode_test/scoring_kaldi/penalty_0.0/log/best_path.17.log \
          lattice-scale --inv-acoustic-scale=17 "ark:gunzip -c ${dir}/decode_test/lat.*.gz|" ark:- \| \
          lattice-add-penalty --word-ins-penalty=0.0 ark:- ark:- \| \
          lattice-best-path --word-symbol-table=$symtab ark:- ark,t:- \| \
          utils/int2sym.pl -f 2- $symtab \| \
          $hyp_filtering_cmd '>' $dir/decode_test/scoring_kaldi/penalty_0.0/17.txt || exit 1;
fi
