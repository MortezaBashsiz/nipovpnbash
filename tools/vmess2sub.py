#!/usr/bin/python3
# -*- coding: utf-8 -*-
import json
import argparse
import base64
import warnings

def Str2Base64(txt):
    return base64.urlsafe_b64encode(txt.encode('utf-8')).decode()

def Conf2v2rayN(conf):
    '''
    Convert v2rayN format json file to v2rayN format vmess link
    '''

    link = ['vmess://' + Str2Base64(json.dumps(i)) for i in conf]
    return link

def Conf2sr(conf, security='aes-128-gcm', allowInsecure=False):
    '''
    Convert v2rayN format json file to shadowrocket format vmess link
    '''
    link = []
    for iconf in conf:
        prefixTxt = '%s:%s@%s:%s' % (security, iconf['id'], iconf['add'], iconf['port'])
        prefix = 'vmess://' + Str2Base64(prefixTxt)
        postfixList = []

        if len(iconf['ps']) > 0:
            postfixList.append('remarks=%s' % (iconf['ps']))

        if len(iconf['host']) > 0:
            postfixList.append('obfsParam=%s' % (iconf['host']))

        if len(iconf['path']) > 0:
            postfixList.append('path=%s' % (iconf['path']))

        if iconf['net'] == 'ws':
            postfixList.append('obfs=websocket')
        elif iconf['net'] == 'kcp':
            raise ValueError('ShadowRocket doesn''t support KCP')
        else:
            if iconf['net'] == 'h2':
                warning.warn('I''m not sure if HTTP/2 works on ShadowRocket')
            postfixList.append('obfs=%s' % (iconf['type']))

        if iconf['tls'] == 'tls':
            postfixList.append('tls=1')

        if allowInsecure:
            postfixList.append('allowInsecure=1')

        ilink = prefix + '?' + '&'.join(postfixList)
        link.append(ilink)
    return link

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='generate vmess links from v2rayN configuration file')

    parser.add_argument('CONF', help='v2rayN configration file')
    parser.add_argument('OUTPUT', help='HTML file for subscription')
    parser.add_argument('-l', '--link', default='STDOUT', help='file to store vmess links (default: STDOUT)')
    parser.add_argument('-t', dest='t', default='v2rayN', choices=['v2rayN', 'sr'], help='type of vmess link (default: %(default)s)')

    ARGS = parser.parse_args()
    with open(ARGS.CONF, 'r') as f:
        conf = json.load(f)

    if ARGS.t == 'v2rayN':
        link = Conf2v2rayN(conf)
    elif ARGS.t == 'sr':
        link = Conf2sr(conf)

    text = '\n'.join(link)
    html = Str2Base64(text)

    with open(ARGS.OUTPUT, 'w', encoding='utf-8') as f:
        f.write(html)

    if ARGS.link == 'STDOUT':
        for i in link:
            print(i + '\n')
    else:
        with open(ARGS.link, 'w', encoding='utf-8') as f:
            for i in link:
                f.write(i + '\n')
