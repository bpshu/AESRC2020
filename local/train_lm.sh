#!/bin/bash


text=data/data_all/text
lexicon=data/local/dict_nosp/lexicon.txt
dir=data/local/lm
mkdir -p $dir
lmFile=$dir/lm.order3.arpa.gz
stage=1

. ./path.sh
. parse_options.sh

cleantext=$dir/text.no_oov

if [ $stage -le 9 ];then
    cat $text | awk -v lex=$lexicon 'BEGIN{while((getline<lex) >0){ seen[$1]=1; } } 
	 {for(n=1; n<=NF;n++) {  if (seen[$n]) { printf("%s ", $n); } else {printf("<UNK> ");} } printf("\n");}' \
	 > $cleantext || exit 1;
    cat $cleantext | awk '{for(n=2;n<=NF;n++){ printf $n; if(n<NF) printf " "; else print ""; }}' > $dir/train
	    
    cat $cleantext | awk '{for(n=2;n<=NF;n++) print $n; }' | \
	    cat - <(grep -w -v '!SIL' $lexicon | awk '{print $1}') | \
	    sort | uniq -c | sort -nr > $dir/unigram.counts || exit 1;

    cat $dir/unigram.counts  | awk '{print $2}' | get_word_map.pl "<s>" "</s>" "<UNK>" > $dir/word_map

    cat $dir/word_map | awk '{print $1}' | cat - <(echo "<s>"; echo "</s>" ) > $dir/wordlist
fi

if [ $stage -le 10 ];then
    ngram-count -text $dir/train -order 3 -limit-vocab -vocab $dir/wordlist -unk \
	-map-unk "<UNK>" -kndiscount -interpolate -lm $lmFile
fi
