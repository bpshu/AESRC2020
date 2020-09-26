#!/bin/bash

# Copyright 2020 Audio, Speech and Language Processing Group @ NWPU (Author: Xian Shi)
# Apache 2.0


raw_data=/data2/multiData/AESRC/2020AESRC     # raw data with metadata, txt and wav
data=data         # data transformed into kaldi format

stage=1
nj=200

vocab_size=1000

. ./path.sh
. ./cmd.sh
. parse_options.sh


# unzip and rename each accent
if [ $stage -le 1 ];then
    # unzip $zipped_data
    mv $raw_data/American\ English\ Speech\ Data $raw_data/US
    mv $raw_data/British\ English\ Speech\ Data $raw_data/UK
    mv $raw_data/Chinese\ Speaking\ English\ Speech\ Data $raw_data/CHN 
    mv $raw_data/Indian\ English\ Speech\ Data $raw_data/IND 
    mv $raw_data/Portuguese\ Speaking\ English\ Speech\ Data $raw_data/PT 
    mv $raw_data/Russian\ Speaking\ English\ Speech\ Data $raw_data/RU 
    mv $raw_data/Japanese\ Speaking\ English\ Speech\ Data $raw_data/JPN 
    mv $raw_data/Korean\ Speaking\ English\ Speech\ Data $raw_data/KR
fi


# generate kaldi format data for all
if [ $stage -le 2 ];then 
    echo "Generating kaldi format data."
    mkdir -p $data/data_all
    find $raw_data -name '*.wav' > $data/data_all/wavpath
    awk -F'/' '{print $(NF-2)"-"$(NF-1)"-"$NF}' $data/data_all/wavpath | sed 's:\.wav::g' > $data/data_all/uttlist
    paste $data/data_all/uttlist $data/data_all/wavpath > $data/data_all/wav.scp
    python local/tools/preprocess.py $data/data_all/wav.scp $data/data_all/trans $data/data_all/utt2spk # faster than for in shell
    ./utils/utt2spk_to_spk2utt.pl $data/data_all/utt2spk > $data/data_all/spk2utt
fi


# clean transcription
if [ $stage -le -3 ];then
    echo "Cleaning transcription."
    tr '[a-z]' '[A-Z]' < $data/data_all/trans > $data/data_all/trans_upper
    # turn "." in specific abbreviations into "<m>" tag
    sed -i -e 's: MR\.: MR<m>:g' -e 's: MRS\.: MRS<m>:g' -e 's: MS\.: MS<m>:g' \
        -e 's:^MR\.:MR<m>:g' -e 's:^MRS\.:MRS<m>:g' -e 's:^MS\.:MS<m>:g' $data/data_all/trans_upper 
    sed -i 's:ST\.:STREET:g' $data/data_all/trans_upper 
    # punctuation marks
    sed -i "s%,\|\.\|?\|!\|;\|-\|:\|,'\|\.'\|?'\|!'\|\ '\|\"% %g" $data/data_all/trans_upper
    sed -i 's:<m>:.:g' $data/data_all/trans_upper
    # blank
    sed -i 's:[ ][ ]*: :g' $data/data_all/trans_upper
    paste $data/data_all/uttlist $data/data_all/trans_upper > $data/data_all/text
    cat $ $data/data_all/text | awk '{for(i=2;i<=NF;i++){print $i}}' | sort -u  >  $data/data_all/word.list
fi


if [ $stage -le 3 ];then 

   paste $data/data_all/uttlist $data/data_all/trans > $data/data_all/text.tmp
   python3 local/segmenter.py $data/data_all/text.tmp $data/data_all/text
   cat $data/data_all/text | awk '{for(i=2;i<=NF;i++){print $i}}' | sort -u  > $data/data_all/word.list
fi

# divide development set for cross validation
if [ $stage -le 4 ];then 
    for i in US UK IND CHN JPN PT RU KR;do 
        ./utils/subset_data_dir.sh --spk-list local/files/cvlist/${i}_cv_spk $data/data_all $data/cv/$i 
        cat $data/cv/$i/wav.scp >> $data/cv.scp 
    done
    ./utils/filter_scp.pl --exclude $data/cv.scp $data/data_all/wav.scp > $data/train.scp 
    ./utils/subset_data_dir.sh --utt-list $data/train.scp $data/data_all $data/train
	./utils/subset_data_dir.sh --utt-list $data/cv.scp $data/data_all $data/dev
    rm $data/cv.scp $data/train.scp 
    #
     ./utils/fix_data_dir.sh $data/train
     ./utils/fix_data_dir.sh $data/dev
     for i in US UK IND CHN JPN PT RU KR;do
     	./utils/fix_data_dir.sh $data/cv/$i
     done
fi

echo "local/prepare_data.sh succeeded"
exit 0;
