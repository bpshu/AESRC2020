#!/usr/bin/env bash

#Copyright 2019-2020 chaoyi.wang
#          2019-2020 beiping.shu

set -e
#
stage=0
nj=200

. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh  # e.g. this parses the above options
                            # if supplied.

#
mfccdir=mfcc
data_mfcc=data_mfcc

if [ ! -d $data_mfcc/train_hires ];then
	mkdir -p $data_mfcc
	cp -r data/train $data_mfcc/train_hires
	cp -r data/dev $data_mfcc/dev_hires
	cp -r data/cv $data_mfcc/cv_hires
fi


for x in train dev; do
  (nj_=$nj
  spk_num=`cat ${data_mfcc}/${x}_hires/spk2utt | wc -l`
  if [ $spk_num -le ${nj_} ];then
    nj_=$spk_num
  fi
  steps/make_mfcc.sh --cmd "$train_cmd" --nj ${nj_}  --mfcc-config conf/mfcc_hires.conf ${data_mfcc}/${x}_hires exp/make_mfcc/${x}_hires ${mfccdir} || exit 1;
  steps/compute_cmvn_stats.sh ${data_mfcc}/${x}_hires exp/make_mfcc/${x}_hires $mfccdir || exit 1;
  utils/fix_data_dir.sh $data_mfcc/${x}_hires || exit 1;
  )&
done

wait

for x in US UK IND CHN JPN PT RU KR; do
  (nj_=$nj
  spk_num=`cat $data_mfcc/cv_hires/$x/spk2utt | wc -l`
  if [ $spk_num -le $nj_ ];then
    nj_=$spk_num
  fi
  steps/make_mfcc.sh --cmd "$train_cmd" --nj ${nj_}  --mfcc-config conf/mfcc_hires.conf $data_mfcc/cv_hires/${x} exp/make_mfcc/cv_hires/${x} $mfccdir || exit 1;
  steps/compute_cmvn_stats.sh $data_mfcc/cv_hires/${x} exp/make_mfcc/cv_hires/${x} $mfccdir || exit 1;
  utils/fix_data_dir.sh $data_mfcc/cv_hires/${x} || exit 1;
  )&
done

wait
