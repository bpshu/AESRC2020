#!/bin/bash

stage=$1

dataDir=/data2/multiData/AESRC/2020AESRC
tmpDir=data/local/data

if [ $stage -le 1 ]; then
	find $dataDir -name "*.wav" > $tmpDir/wav.list
	cat $tmpDir/wav.list | awk -F '/' '{print $NF}' | awk -F'.' '{print $1}' > $tmpDir/id.list
	cat $tmpDir/wav.list | awk -F '/' '{print $(NF-1)}' > $tmpDir/speaker.list
	paste -d' ' $tmpDir/id.list $tmpDir/wav.list | sort > $tmpDir/wav.scp
	paste -d' ' $tmpDir/id.list $tmpDir/speaker.list  | sort > $tmpDir/utt2spk
	cat $tmpDir/utt2spk | awk -F' ' '{print $2 " " $1}' > $tmpDir/spk2utt

	find $dataDir -name "*.txt" > $tmpDir/txt.list

	cat $tmpDir/txt.list  |awk '{print $0}' | \
	   perl -e ' 
		while(<>){
		    open CF, $_ or die "cannot open";
		    @arr = split /\//, $_;
		    @row = split /\./, $arr[$#arr];
		    $id=$row[0];
		    $text="";
		    while(<CF>){
			chomp;
			$text = $text." ".$_;
		    }
		    print $id.$text."\n";
		}' | sort > $tmpDir/text.tmp
fi

if [ $stage -le 2 ]; then
    python3 local/segmenter.py $tmpDir/text.tmp $tmpDir/text
    cat data/local/data/text | awk '{for(i=2;i<=NF;i++){print $i}}' | sort -u  > data/local/data/word.list
fi

if [ $stage -le 3 ]; then
  
fi
