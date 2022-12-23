#!/bin/bash  -
#===============================================================================
#
#          FILE: config.sh
#
#         USAGE: ./config.sh
#
#   DESCRIPTION: 
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Morteza Bashsiz (mb), morteza.bashsiz@gmail.com
#  ORGANIZATION: Linux
#       CREATED: 11/01/2022 03:47:19 PM
#      REVISION:  ---
#===============================================================================

set -o nounset                                  # Treat unset variables as an error

_pass=$(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c"${1:-16}";echo;)
_uuid=$(cat /proc/sys/kernel/random/uuid)

_INTERNAL_IPTABLES_CFG=$(cat << EOF
*filter
:INPUT ACCEPT [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -d $_INTERNAL_IP/32 -p udp -m udp --dport $_INTERNAL_VPN_PORT -j ACCEPT
-A INPUT -d $_INTERNAL_IP/32 -p tcp -m tcp --dport $_INTERNAL_VPN_PORT -j ACCEPT
-A INPUT -p tcp -m tcp --dport $_INTERNAL_SSH_PORT -j ACCEPT
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -j DROP
-A FORWARD -d $_EXTERNAL_IP/32 -j ACCEPT
-A FORWARD -s $_EXTERNAL_IP/32 -j ACCEPT
-A FORWARD -j DROP
-A OUTPUT -j ACCEPT
COMMIT
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A PREROUTING -d $_INTERNAL_IP/32 -p udp -m udp --dport $_INTERNAL_VPN_PORT -j DNAT --to-destination $_EXTERNAL_IP:$_EXTERNAL_VPN_PORT 
-A PREROUTING -d $_INTERNAL_IP/32 -p tcp -m tcp --dport $_INTERNAL_VPN_PORT -j DNAT --to-destination $_EXTERNAL_IP:$_EXTERNAL_VPN_PORT
-A POSTROUTING -j MASQUERADE
COMMIT
EOF
)

_EXTERNAL_IPTABLES_CFG=$(cat << EOF
*filter
:INPUT ACCEPT [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -d $_EXTERNAL_IP/32 -p udp -m udp --dport $_EXTERNAL_VPN_PORT -j ACCEPT
-A INPUT -d $_EXTERNAL_IP/32 -p tcp -m tcp --dport $_EXTERNAL_VPN_PORT -j ACCEPT
-A INPUT -p tcp -m tcp --dport $_EXTERNAL_SSH_PORT -j ACCEPT
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -j DROP
-A FORWARD -j DROP
-A OUTPUT -j ACCEPT
COMMIT
EOF
)

_FAIL2BAN_CFG=$(cat << EOF
[sshd]
enabled = true
bantime = 15m
findtime = 10m
maxretry = 3
EOF
)

_SYSCTL_CFG="net.ipv4.ip_forward = 1"

_SHADOWSOCKS_CFG=$(cat << EOF
{
    "server":"$_EXTERNAL_IP",
    "server_port":$_EXTERNAL_VPN_PORT,
    "local_port":1080,
    "password":"$_pass",
    "timeout":300,
    "method":"chacha20-ietf-poly1305",
    "workers":8,
    "plugin":"obfs-server",
    "plugin_opts": "obfs=http;obfs-host=www.google.com",
    "fast_open":true,
    "reuse_port":true
}
EOF
)

_V2RAY_VMESS_SYSTEMD_CFG=$(cat << EOF
[Service]
Environment=V2RAY_VMESS_AEAD_FORCED=false
EOF
)

_V2RAY_VMESS_CFG=$(cat << EOF
{
  "inbounds": [{
    "listen": "$_EXTERNAL_IP",
    "port": $_EXTERNAL_VPN_PORT,
    "protocol": "vmess",
    "streamSettings": {},
    "settings": {
      "clients": [
        {
          "id": "$_uuid",
          "level": 1,
          "alterId": 64
        }
      ]
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }]
}
EOF
)

_V2RAY_VMESS_WS_CFG=$(cat << EOF
{
  "inbounds": [{
    "listen": "127.0.0.1",
    "port": 10000,
    "protocol": "vmess",
    "streamSettings": {
        "network": "ws",
        "wsSettings": {
        "path": "/adaspolo"
        }
		},
    "settings": {
      "clients": [
        {
          "id": "$_uuid",
          "level": 1,
          "alterId": 64
        }
      ]
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }]
}
EOF
)

_V2RAY_VMESS_WS_NGINX_CFG=$(cat << EOF
server {
  listen $_EXTERNAL_VPN_PORT;
  server_name           sudoer.online;
    location /adaspolo { # Consistent with the path of V2Ray configuration
      if (\$http_upgrade != "websocket") { # Return 404 error when WebSocket upgrading negotiate failed
          return 404;
      }
      proxy_redirect off;
      proxy_pass http://127.0.0.1:10000; # Assume WebSocket is listening at localhost on port of 10000
      proxy_http_version 1.1;
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header Host \$host;
      # Show real IP in v2ray access.log
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF
)

_TROJAN_CFG=$(cat << EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": $_EXTERNAL_VPN_PORT,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "$_pass"
    ],
    "log_level": 1,
    "ssl": {
        "cert": "/etc/trojan/ssl.cert",
        "key": "/etc/trojan/ssl.key",
        "key_password": "",
        "cipher": "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384",
        "cipher_tls13": "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
        "prefer_server_cipher": true,
        "alpn": [
            "http/1.1"
        ],
        "alpn_port_override": {
            "h2": 81
        },
        "reuse_session": true,
        "session_ticket": false,
        "session_timeout": 600,
        "plain_http_response": "",
        "curves": "",
        "dhparam": ""
    },
    "tcp": {
        "prefer_ipv4": false,
        "no_delay": true,
        "keep_alive": true,
        "reuse_port": false,
        "fast_open": false,
        "fast_open_qlen": 20
    },
    "mysql": {
        "enabled": false,
        "server_addr": "127.0.0.1",
        "server_port": 3306,
        "database": "trojan",
        "username": "trojan",
        "password": "",
        "key": "",
        "cert": "",
        "ca": ""
    }
}
EOF
)

_ARVAN_FAIL2BAN_CFG=$(cat << EOF
[sshd]
enabled = true
bantime = 15m
findtime = 10m
maxretry = 3
EOF
)

_ARVAN_VM_IPTABLES_CFG=$(cat << EOF
*filter
:INPUT ACCEPT [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -d $_ARVAN_VM_IP/32 -p udp -m udp --dport 443 -j ACCEPT
-A INPUT -d $_ARVAN_VM_IP/32 -p tcp -m tcp --dport 443 -j ACCEPT
-A INPUT -p tcp -m tcp --dport $_ARVAN_VM_SSH_PORT -j ACCEPT
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -j DROP
-A FORWARD -j DROP
-A OUTPUT -j ACCEPT
COMMIT
EOF
)

_ARVAN_V2RAY_VMESS_SYSTEMD_CFG=$(cat << EOF
[Service]
Environment=V2RAY_VMESS_AEAD_FORCED=false
EOF
)

_ARVAN_V2RAY_CFG=$(cat << EOF
{
  "log": {
    "loglevel": "debug"
  },
  "inbounds": [{
    "listen": "127.0.0.1",
    "port": 4443,
    "protocol": "vmess",
    "streamSettings": {
        "network": "ws",
        "wsSettings": {
        "path": "/adaspolo"
        }
		},
    "settings": {
      "clients": [
        {
          "id": "$_uuid",
          "level": 1,
          "alterId": 64
        }
      ]
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }]
}
EOF
)

_ARVAN_NGINX_CFG=$(cat << EOF
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
	worker_connections 1024;
}

http {
	sendfile on;
	tcp_nopush on;
	types_hash_max_size 2048;
  client_body_buffer_size 10K;
	client_header_buffer_size 1k;
	client_max_body_size 8m;
	large_client_header_buffers 4 4k;
	client_body_timeout 12;
	client_header_timeout 12;
	keepalive_timeout 15;
	send_timeout 10;

	include /etc/nginx/mime.types;
	default_type application/octet-stream;

	ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE
	ssl_prefer_server_ciphers on;

	access_log /var/log/nginx/access.log;
	error_log /var/log/nginx/error.log;

	server {
	
	    listen 80;
	    server_name gheychivpn.$_ARVAN_DOMAIN vpn.$_ARVAN_DOMAIN ;
	    return 301 https://gheychivpn.$_ARVAN_DOMAIN;
	}
		
	server {
	    gzip on;
	    gzip_disable "msie6";
	    gzip_vary on;
	    gzip_proxied any;
	    gzip_comp_level 6;
	    gzip_buffers 16 8k;
	    gzip_http_version 1.1;
	    gzip_types application/javascript application/rss+xml application/vnd.ms-fontobject application/x-font application/x-font-opentype application/x-font-otf application/x-font-truetype application/x-font-ttf application/x-javascript application/xhtml+xml application/xml font/opentype font/otf font/ttf image/svg+xml image/x-icon text/css text/javascript text/plain text/xml;
	    if (\$host !~ ^(gheychivpn.$_ARVAN_DOMAIN|vpn.$_ARVAN_DOMAIN)$ ) {
	        return 444;
	    }
	    if (\$request_method !~ ^(GET|HEAD|POST)$ ) {
	        return 444;
	    }
	    listen 443 ssl http2;
	    server_name gheychivpn.$_ARVAN_DOMAIN vpn.$_ARVAN_DOMAIN;
	
	    root /usr/share/nginx/html;
	    index index.html;
	    ssl_certificate /etc/letsencrypt/live/vpn.$_ARVAN_DOMAIN/fullchain.pem;
	    ssl_certificate_key /etc/letsencrypt/live/vpn.$_ARVAN_DOMAIN/privkey.pem;
	    ssl_trusted_certificate /etc/letsencrypt/live/vpn.$_ARVAN_DOMAIN/chain.pem;
	    access_log /var/log/nginx/vpn.$_ARVAN_DOMAIN.access.log;
	    error_log /var/log/nginx/vpn.$_ARVAN_DOMAIN.error.log;
	
	    location = /favicon.ico {
	        log_not_found off;
	        access_log off;
	    }
	
	    location = /robots.txt {
	        allow all;
	        log_not_found off;
	        access_log off;
	    }
		location /adaspolo {
		    proxy_redirect off;
		    proxy_pass          http://localhost:4443;
		    proxy_http_version 1.1;
		    proxy_set_header Upgrade \$http_upgrade;
		    proxy_set_header Connection "upgrade";
		    proxy_set_header Host \$http_host;
		}
	}
}
EOF
)
