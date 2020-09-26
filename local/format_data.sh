#!/usr/bin/env bash

# Copyright 2014 Vassil Panayotov
# Apache 2.0

# Prepares the test time language model(G) transducers
# (adapted from wsj/s5/local/wsj_format_data.sh)

. ./path.sh

if [ $# -ne 1 ]; then
  echo "Usage: $0 <lm-dir>"
  echo "e.g.: $0 /export/a15/vpanayotov/data/lm"
  echo ", where:"
  echo "    <lm-dir> is the directory in which the language model is stored/downloaded"
  exit 1
fi

lm_dir=$1

# This loop was taken verbatim from wsj_format_data.sh, and I'm leaving it in place in
# case we decide to add more language models at some point
for lm_suffix in order3; do
  test=data/lang_test_${lm_suffix}
  mkdir -p $test
  for f in phones.txt words.txt phones.txt L.fst L_disambig.fst phones topo oov.txt oov.int; do
    cp -r data/lang_nosp/$f $test
  done
  gunzip -c $lm_dir/lm.${lm_suffix}.arpa.gz | \
    arpa2fst --disambig-symbol=#0 \
             --read-symbol-table=$test/words.txt - $test/G.fst

  utils/validate_lang.pl $test || exit 1;
done

echo "Succeeded in formatting data."

exit 0
