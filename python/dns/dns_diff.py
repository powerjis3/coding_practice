#!/usr/bin/env python3

import sys
import json

def Usage():
    print("usage: ./dns_diff.py [src.txt] [compare.txt]")

def main():
    if len(sys.argv) != 3:
        Usage()
        sys.exit()

    srcTxt = sys.argv[1]
    cmpTxt = sys.argv[2]

    f1 = open(srcTxt, 'r')
    f2 = open(cmpTxt, 'r')

    srcData = f1.readlines()
    cmpData = f2.readlines()

    cnt = 0
    print("------------")
    
    for cmpline in cmpData:
        for srcline in srcData:
            if srcline == cmpline:
                print(cmpline)
                cnt += 1

    print("--------------")
    print("Total Matched : %d" %cnt)
    
    f1.close()
    f2.close()

if __name__ == '__main__':
    main()
