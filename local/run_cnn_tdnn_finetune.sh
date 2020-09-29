#!/usr/bin/env bash

#Copyright 2019-2020 beiping.shu

set -e
# configs for 'chain'
stage=15
train_stage=0
get_egs_stage=-10
#
train_nj=200
decode_nj=20
# training options
frames_per_eg=150,110,100
remove_egs=false
common_egs_dir=
xent_regularize=0.1
srand=0
# tuning-config
primary_lr_factor=0.25 # learning-rate factor for all except last layer in transferred source model
phone_lm_scales="1,10" # comma-separated list of positive integer multiplicities
                       # to apply to the different source data directories (used
                       # to give the RM dat

# End configuration section.
echo "$0 $@"  # Print the command line for logging

. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh

tuning_dir=/data/002.data.beiping.shu/kaldi/egs/librispeech/s5

chain_tdnn_treedir=$tuning_dir/exp/tree_sp
lang=data_mfcc/lang
chain_cnn_dir=$tuning_dir/exp/chain_cleaned/tdnn_cnn_1a_sp
lat_dir=exp/chain_cnn_lat
dir=exp/chain_cnn_tuning
train_feats=data_mfcc/train_hires
ivector_dir=exp/ivectors_train_hires

if [ $stage -le 15 ]; then
  # Get the alignments as lattices (gives the chain training more freedom).
  # use the same num-jobs as the alignments
  ivec_opt="--online-ivector-dir ${ivector_dir}"
  bash steps/nnet3/align_lats.sh --nj $train_nj --cmd "$train_cmd" $ivec_opt \
    --generate-ali-from-lats true \
    --acoustic-scale 1.0 --extra-left-context-initial 0 --extra-right-context-final 0 \
    --frames-per-chunk 150 \
    --scale-opts "--transition-scale=1.0 --self-loop-scale=1.0" \
    $train_feats $lang $chain_cnn_dir $lat_dir || exit 1;
  rm $lat_dir/fsts.*.gz # save space
fi

if [ $stage -le 16 ]; then
  # Set the learning-rate-factor for all transferred layers but the last output
  # layer to primary_lr_factor.
  $train_cmd $dir/log/generate_input_mdl.log \
    nnet3-am-copy --raw=true --edits="set-learning-rate-factor name=* learning-rate-factor=$primary_lr_factor; set-learning-rate-factor name=output* learning-rate-factor=1.0" \
      $chain_cnn_dir/final.mdl $dir/input.raw || exit 1;
fi

if [ $stage -le 17 ]; then
  echo "$0: compute {den,normalization}.fst using weighted phone LM."
  steps/nnet3/chain/make_weighted_den_fst.sh --cmd "$train_cmd" \
    --num-repeats $phone_lm_scales \
    --lm-opts '--num-extra-lm-states=200' \
    $chain_tdnn_treedir $lat_dir $dir || exit 1;
fi

if [ $stage -le 18 ]; then
  # exclude phone_LM and den.fst generation training stage
  #if [ $train_stage -lt -4 ]; then train_stage=-4 ; fi
  # we use chain model from source to generate lats for target and the
  # tolerance used in chain egs generation using this lats should be 1 or 2 which is
  # (source_egs_tolerance/frame_subsampling_factor)
  # source_egs_tolerance = 5
  chain_opts=(--chain.alignment-subsampling-factor=1 --chain.left-tolerance=1 --chain.right-tolerance=1)
  steps/nnet3/chain/train.py --stage $train_stage ${chain_opts[@]} \
    --cmd "$cuda_cmd" \
    --use-gpu "true" \
    --trainer.input-model $dir/input.raw \
    --feat.online-ivector-dir "$ivector_dir" \
    --feat.cmvn-opts "--norm-means=false --norm-vars=false" \
    --chain.xent-regularize 0.1 \
    --chain.leaky-hmm-coefficient 0.1 \
    --chain.l2-regularize 0.00005 \
    --chain.apply-deriv-weights false \
    --egs.dir "$common_egs_dir" \
    --egs.opts "--frames-overlap-per-eg 0" \
    --egs.chunk-width 150 \
    --trainer.num-chunk-per-minibatch=128 \
    --trainer.frames-per-iter 1000000 \
    --trainer.num-epochs 4 \
    --trainer.optimization.num-jobs-initial=1 \
    --trainer.optimization.num-jobs-final=1 \
    --trainer.optimization.initial-effective-lrate=0.0005 \
    --trainer.optimization.final-effective-lrate=0.00005 \
    --trainer.max-param-change 2.0 \
    --cleanup.remove-egs false \
    --feat-dir $train_feats \
    --tree-dir $chain_tdnn_treedir \
    --lat-dir $lat_dir \
    --dir $dir || exit 1;
fi

if [ $stage -le 19 ]; then
# Note: it might appear that this $lang directory is mismatched, and it is as
  # far as the 'topo' is concerned, but this script doesn't read the 'topo' from
  # the lang directory.
  tes_ivec_opt=""
  if $use_ivector;then test_ivec_opt="--online-ivector-dir ../s5/exp/ivectors_dev_hires" ; fi

  utils/mkgraph.sh --self-loop-scale 1.0 $lang $dir $dir/graph
  steps/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 \
    --scoring-opts "--min-lmwt 1" \
    --nj 20 --cmd "$decode_cmd" $test_ivec_opt \
    $dir/graph ../s5/data_mfcc/dev_hires $dir/decode || exit 1;

fi

if [ $stage -le 20 ]; then
	nj=20
	for x in US UK IND CHN JPN PT RU KR; do
		(nj_=$nj
		spk_num=`cat ../s5/data_mfcc/cv_hires/${x}/spk2utt | wc -l`
		if [ $spk_num -le $nj ];then
			nj_=$spk_num;
		fi
		test_ivec_opt=""
		if $use_ivector;then test_ivec_opt="--online-ivector-dir exp/ivectors_cv_hires_${x}" ; fi
		steps/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 \
			--scoring-opts "--min-lmwt 1" \
			--nj $nj_ --cmd "$decode_cmd" $test_ivec_opt \
			$dir/graph data_mfcc/cv_hires/${x} $dir/decode_${x}_hires || exit 1;
		)&
	done
fi

