#!/bin/bash

dir=/data2/multiData/AESRC/test_wav/wav
tmpDir=data/local/test


find $dir -name "*.wav" > $tmpDir/wav.list

cat $tmpDir/wav.list | awk -F'/' '{print $NF}' | awk -F'.' '{print $1}' > $tmpDir/id
paste -d' ' $tmpDir/id $tmpDir/wav.list |  sort -u  > $tmpDir/wav.scp

paste -d' ' $tmpDir/id $tmpDir/id  | sort -u > $tmpDir/utt2spk

cp $tmpDir/utt2spk $tmpDir/spk2utt
cp $tmpDir/utt2spk $tmpDir/text


cp $tmpDir/wav.scp data/test/
cp $tmpDir/text data/test/
cp $tmpDir/utt2spk data/test/
cp $tmpDir/spk2utt data/test/


./utils/fix_data_dir.sh data/test

cp -r data/test data_mfcc/test_hires


