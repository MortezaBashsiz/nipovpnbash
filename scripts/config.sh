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