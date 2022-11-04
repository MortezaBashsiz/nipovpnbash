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
	if [[ "$_DIST" == "UBUNTU" ]]; then
		fncPkgInstall "$_EXTERNAL_IP" "$_EXTERNAL_SSH_PORT" "gnupg ca-certificates curl"
		fncExecCmd "$_EXTERNAL_IP" "$_EXTERNAL_SSH_PORT" "curl -sSL https://apt.v2fly.org/pubkey.gpg | sudo apt-key add -"
		fncExecCmd "$_EXTERNAL_IP" "$_EXTERNAL_SSH_PORT" "echo \"deb [arch=amd64] https://apt.v2fly.org/ stable main\" | sudo tee /etc/apt/sources.list.d/v2ray.list"
	fi
		fncPkgInstall "$_EXTERNAL_IP" "$_EXTERNAL_SSH_PORT" "iptables-persistent"
		fncPkgInstall "$_EXTERNAL_IP" "$_EXTERNAL_SSH_PORT" "htop net-tools vim fail2ban"
	if [[ "$_VPN_SERVICE" == "shadowsocks+obfs" ]]; then
		fncPkgInstall "$_EXTERNAL_IP" "$_EXTERNAL_SSH_PORT" "shadowsocks-libev simple-obfs"
	elif [[ "$_VPN_SERVICE" == "v2ray+vmess" ]]; then
		fncPkgInstall "$_EXTERNAL_IP" "$_EXTERNAL_SSH_PORT" "python3-urllib3 v2ray"
	elif [[ "$_VPN_SERVICE" == "v2ray+vmess+ws" ]]; then
		fncPkgInstall "$_EXTERNAL_IP" "$_EXTERNAL_SSH_PORT" "python3-urllib3 v2ray nginx"
	elif [[ "$_VPN_SERVICE" == "trojan" ]]; then
		fncPkgInstall "$_EXTERNAL_IP" "$_EXTERNAL_SSH_PORT" "trojan"
	fi
}
# End of Function fncInstallExternal

# Function fncInstallInternal
# Installs the packages on external host
function fncInstallInternal {
	fncPkgInstall "$_INTERNAL_IP" "$_INTERNAL_SSH_PORT" "iptables-persistent"
	fncPkgInstall "$_INTERNAL_IP" "$_INTERNAL_SSH_PORT" "htop net-tools vim fail2ban"
}
# End of Function fncInstallExternal
