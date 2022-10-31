#!/usr/bin/python3
# -*- coding: utf-8 -*-
import json
import argparse
import urllib.request
import warnings
import os

V2RAYN_TEMPLATE = {
    'v': '2',
    'ps': '',
    'add': '',
    'port': '',
    'id': '',
    'aid': '0',
    'net': 'tcp',
    'type': 'none',
    'host': '',
    'path': '/',
    'tls': 'none'
}
# Follow v2rayN format: https://github.com/2dust/v2rayN/wiki/%E5%88%86%E4%BA%AB%E9%93%BE%E6%8E%A5%E6%A0%BC%E5%BC%8F%E8%AF%B4%E6%98%8E(ver-2)


def generate_vmess_config(ARGS, V2RAYN_TEMPLATE):
    with open(ARGS.config, 'r') as f:
        config = json.load(f)
    config = config['inbounds']

    configOut = []
    for iconfig in config:
        if 'tag' not in iconfig.keys():
            isVmess = True
        elif iconfig['tag'] == 'vmess':
            isVmess = True

        if isVmess:
            numClient = len(iconfig['settings']['clients'])
            if len(ARGS.port) > 1:
                if len(ARGS.port) != numClient:
                    raise ValueError('cli argument <port> doesn''t match configuration file')
                clientPort = ARGS.port
            else:
                clientPort = ARGS.port * numClient

            LOCAL_TEMPLATE = V2RAYN_TEMPLATE.copy()
            LOCAL_TEMPLATE['add'] = ARGS.server
            if 'network' in iconfig['streamSettings'].keys():
                LOCAL_TEMPLATE['net'] = iconfig['streamSettings']['network']
            if 'security' in iconfig['streamSettings'].keys():
                LOCAL_TEMPLATE['tls'] = iconfig['streamSettings']['security']

            if LOCAL_TEMPLATE['net'] == 'tcp':
                LOCAL_TEMPLATE['type'] = 'none' # default: no obfuscation
                if 'tcpSettings' in iconfig['streamSettings'].keys():
                    warnings.warn('HTTP obfuscation is not recommended')
                    tcpSettings = iconfig['streamSettings']['tcpSettings']
                    if 'header' in tcpSettings:
                        LOCAL_TEMPLATE['type'] = tcpSettings['header']['type']
                        if LOCAL_TEMPLATE['type'] == 'http':
                            # TCP obfuscation doesn't support path
                            # LOCAL_TEMPLATE['path'] = tecpSettings['header']['request']['path']
                            if 'request' in tcpSettings['header']:
                                try:
                                    LOCAL_TEMPLATE['host'] = ','.join(tcpSettings['header']['request']['headers']['Host'])
                                except:
                                    print('No host defined for http obfuscation, default values: [www.amazon.com,www.cloudflare.com] will be used')
                                    LOCAL_TEMPLATE['host'] = 'www.cloudflare.com,www.amazon.com'
            elif LOCAL_TEMPLATE['net'] == 'ws':  # WebSocket
                LOCAL_TEMPLATE['type'] = 'none'
                if 'wsSettings' in iconfig['streamSettings'].keys():
                    wsSettings = iconfig['streamSettings']['wsSettings']
                    if 'path' in wsSettings.keys():
                        LOCAL_TEMPLATE['path'] = wsSettings['path']
                    if 'headers' in wsSettings.keys():
                        if 'Host' in wsSettings['headers'].keys():
                            LOCAL_TEMPLATE['host'] = wsSettings['headers']['Host']
            elif LOCAL_TEMPLATE['net'] == 'h2' or LOCAL_TEMPLATE['net'] == 'http':  # HTTP/2
                LOCAL_TEMPLATE['net'] = 'h2'
                LOCAL_TEMPLATE['type'] = 'none'
                if 'httpSettings' in iconfig['streamSettings'].keys():
                    httpSettings = iconfig['streamSettings']['httpSettings']
                    if 'path' in httpSettings.keys():
                        LOCAL_TEMPLATE['path'] = httpSettings['path']
                    if 'host' in httpSettings.keys():
                        LOCAL_TEMPLATE['host'] = ','.join(httpSettings['host'])
                if LOCAL_TEMPLATE['tls'] == 'none':
                    raise ValueError('HTTP/2 is not configured correctly. TLS is not enabled.')
            elif LOCAL_TEMPLATE['net'] == 'mkcp' or LOCAL_TEMPLATE['net'] == 'kcp': # mkcp
                LOCAL_TEMPLATE['net'] = 'kcp'
                if 'kcpSettings' in iconfig['streamSettings'].keys():
                    kcpSettings = iconfig['streamSettings']['kcpSettings']
                    if 'header' in kcpSettings.keys():
                        if 'type' in kcpSettings['header']:
                            LOCAL_TEMPLATE['type'] = kcpSettings['header']['type']
            else:
                raise ValueError('wrong value for TransportObject: %s' % (LOCAL_TEMPLATE['net']))

            vmessConfig = [LOCAL_TEMPLATE.copy() for i in range(numClient)]
            for i, (iClient, iPort) in enumerate(zip(iconfig['settings']['clients'], clientPort)):
                vmessConfig[i]['port'] = str(iPort)
                vmessConfig[i]['id'] = iClient['id']
                if iClient['alterId']:
                    vmessConfig[i]['aid'] = str(iClient['alterId'])

            for i in vmessConfig:
                configOut.append(i)
    return configOut

if __name__ == '__main__':
    data= urllib.request.urlopen('http://jsonip.com').read().decode()
    publicIP = json.loads(data)['ip']

    parser = argparse.ArgumentParser(description="""Script to generate v2rayN format configuration file based on
    https://github.com/2dust/v2rayN/wiki/%E5%88%86%E4%BA%AB%E9%93%BE%E6%8E%A5%E6%A0%BC%E5%BC%8F%E8%AF%B4%E6%98%8E(ver-2)""")

    parser.add_argument('-c', '--config', default='config.json', help='path of configuration file for v2ray server (default: %(default)s)')
    parser.add_argument('-s', '--server', default=publicIP, help='domain or IP address of v2ray server (default: IP of current host %(default)s)')
    parser.add_argument('-p', '--port', nargs='+', type=int, default=[80], help='ports that v2ray server listens to (default: the ones defined in configuration file)')
    parser.add_argument('-o', '--output', default='STDOUT', help='name of v2rayN format configuration file (default: %(default)s)')
    parser.add_argument('-a', '--append', action='store_true', help='append to output file (default: False)')

    ARGS = parser.parse_args()
    config = generate_vmess_config(ARGS, V2RAYN_TEMPLATE)
    if ARGS.output == 'STDOUT':
        print(json.dumps(config, indent=4, ensure_ascii=False))
    else:
        if ARGS.append:
            if os.path.isfile(ARGS.output):
                with open(ARGS.output, 'r') as f:
                    configOld = json.load(f)
                config = configOld + config
        with open(ARGS.output, 'w', encoding='utf-8') as f:
            json.dump(config, f, indent=4, ensure_ascii=False)
