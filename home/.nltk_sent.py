#!/usr/bin/env python3
import sys
from nltk.tokenize import sent_tokenize
#nltk.data.path.append('CUSTOMPATH')
data = sys.stdin.read()
sent_tokenize_list = sent_tokenize(data.replace('\n', ' '))
for line in sent_tokenize_list:
    print(line)
    print()
