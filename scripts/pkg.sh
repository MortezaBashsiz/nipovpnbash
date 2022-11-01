#!/bin/bash  -
#===============================================================================
#
#          FILE: pkg.sh
#
#         USAGE: ./pkg.sh
#
#   DESCRIPTION: 
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Morteza Bashsiz (mb), morteza.bashsiz@gmail.com
#  ORGANIZATION: Linux
#       CREATED: 10/30/2022 09:16:51 PM
#      REVISION:  ---
#===============================================================================

set -o nounset                                  # Treat unset variables as an error

# Function fncInstallExternal
# Installs the packages on external host
function fncInstallExternal {
		fncPkgInstall "$_EXTERNAL_IP" "$_EXTERNAL_SSH_PORT" "htop net-tools iptables-persistent vim fail2ban"
	if [[ "$_VPN_SERVICE" == "shadowsocks+obfs" ]]; then
		fncPkgInstall "$_EXTERNAL_IP" "$_EXTERNAL_SSH_PORT" "shadowsocks-libev simple-obfs"
	elif [[ "$_VPN_SERVICE" == "v2ray+vmess" ]]; then
		fncPkgInstall "$_EXTERNAL_IP" "$_EXTERNAL_SSH_PORT" "python3-urllib3 v2ray"
	elif [[ "$_VPN_SERVICE" == "v2ray+vmess+ws+tls" ]]; then
		fncPkgInstall "$_EXTERNAL_IP" "$_EXTERNAL_SSH_PORT" "python3-urllib3 v2ray nginx"
	fi
}
# End of Function fncInstallExternal

# Function fncInstallInternal
# Installs the packages on external host
function fncInstallInternal {
	fncPkgInstall "$_INTERNAL_IP" "$_INTERNAL_SSH_PORT" "htop net-tools iptables-persistent vim fail2ban"
}
# End of Function fncInstallExternal
