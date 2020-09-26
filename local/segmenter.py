#!/usr/bin/python3
#coding=utf-8

import string
import sys
import regex

#print("所有英文符号：", string.punctuation)

class BaseSegmenter:
    punct = regex.compile(r'\p{Punct}')
    enChar = regex.compile(r'[A-Za-z0-9 ]')
    decimal = regex.compile(r'(\d+)\.(\d+)')
    other1 = regex.compile(r'[A-Za-z0-9]\-[A-Za-z0-9]')

    def __init__(self, lexicon_path: str):
        self.phrases = self.__load_phrases(lexicon_path)
        #self.lexicon = set(phrases)
        punct_en = string.punctuation
        self.punct_en_noEps = punct_en.replace('\'', '')

    def __load_phrases(self, path):
        # lexicon syntax:
        # <word> *<phones>
        with open(path) as __file:
            lines = __file.readlines()
        phrases_set = {l.split(maxsplit=2)[0] for l in lines}
        phrases = sorted(phrases_set, key=lambda ph:(len(ph), ph), reverse=True)
        return phrases

    def delSymInWord(self, word:str):
        if len(word) == 0:
            return
        if not self.enChar.search(word):
            return ""
        if self.enChar.match(word[0]) and self.enChar.match(word[-1]):
            return word
        ind_s = 0
        ind_e = len(word)-1
        for ind in range(len(word)):
            if self.enChar.match(word[ind]):
                ind_s = ind
                break
        for ind in range(len(word)-1, -1, -1):
            if self.enChar.match(word[ind]):
                ind_e = ind
                break
        if ind_s > ind_e:
            print("error", word)
            return word
        return word[ind_s:ind_e+1]

    def apply(self, text: str):
        text = regex.compile(r'(?<=\S)([,?!:])(?=\S)').sub(r'\1 ', text)   
        text = text.upper()
        text = regex.compile(r'ST\.').sub('STREET', text)
        text = regex.compile(r'\-').sub('\ ', text)
        text = regex.compile(r'\ MR\.').sub('\ MRSHUBEIPING', text)
        text = regex.compile(r'\ MRS\.').sub('\ MRSSHUBEIPING', text)
        text = regex.compile(r'\ MS\.').sub('\ MSSHUBEIPING', text)
        text = regex.compile(r'^MR\.').sub('MRSHUBEIPING', text)
        text = regex.compile(r'^MRS\.').sub('MRSSHUBEIPING', text)
        text = regex.compile(r'^MS\.').sub('MSSHUBEIPING', text)
        tokens = text.split()
        for n, tk in enumerate(tokens):
            tokens[n] = self.delSymInWord(tk)
            tokens[n] = regex.compile(r'SHUBEIPING').sub('.', tokens[n])
        #print(" ".join(tokens))
        return tokens

if __name__ == "__main__":

    lexicon_path='data/local/lm/cmudict-0.7b'
    lexicon_path="/data/002.data.beiping.shu/kaldi/egs/librispeech/s5/data/local/dict_nosp/lexicon.txt"
    s = BaseSegmenter(lexicon_path)
    #s.apply("MY ''NAME'S SHU-BEI-PING, DR. M.S. 'SHU. !BEI PING'")
    textFile=sys.argv[1]

    with open(sys.argv[2], 'w') as fw:
        with open(sys.argv[1], 'r', encoding='utf-8') as f:
            for line in f.readlines():
                arr = line.strip().split()
                l = arr[0] + " " + " ".join(s.apply(" ".join(arr[1:])))
                fw.write(l+"\n")

