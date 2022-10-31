#!/usr/bin/python3
# -*- coding: utf-8 -*-
import json
import argparse
import base64
import warnings

def Str2Base64(txt):
    return base64.urlsafe_b64encode(txt.encode('utf-8')).decode()

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='generate vmess links from v2rayN configuration file')

    parser.add_argument('LINK', help='file containing a list of sr/vmess links seperatated by "\n"')
    parser.add_argument('OUTPUT', help='HTML file for subscription')

    ARGS = parser.parse_args()
    with open(ARGS.LINK, 'r', encoding='utf-8') as f:
        links = f.readlines()

    links = [i.replace('\n','').replace('\r','') for i in links]
    text = '\n'.join(links)
    html = Str2Base64(text)

    with open(ARGS.OUTPUT, 'w', encoding='utf-8') as f:
        f.write(html)
