#!/usr/bin/python3
# -*- coding: utf-8 -*-
import argparse
import base64
import sys

def Str2Base64(txt):
    # shadowrocket doesn't like padding
    return base64.urlsafe_b64encode(txt.encode('utf-8')).decode().replace('=','')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="generate link for subscription in ShadowRocket")

    parser.add_argument('LINK', help='url of the html file, e.g.: http://admin:password@example.com/v2ray.html')
    parser.add_argument('-l','--label', default='', help="a label to distinguish different subscription links served on the same server")

    ARGS = parser.parse_args()
    txt = 'sub://' + Str2Base64(ARGS.LINK) + '#' + ARGS.label
    sys.stdout.write(txt)
