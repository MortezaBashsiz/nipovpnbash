#!/bin/bash  -
#===============================================================================
#
#          FILE: nipovpn.sh
#
#         USAGE: ./nipovpn.sh
#
#   DESCRIPTION: install and configure vpn
#
#       OPTIONS: ---
#  REQUIREMENTS: Debian 11
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Morteza Bashsiz (mb), morteza.bashsiz@gmail.com
#  ORGANIZATION: Linux
#       CREATED: 10/30/2022 08:46:11 PM
#      REVISION:  ---
#===============================================================================

set -o nounset                                  # Treat unset variables as an error

source basic.sh
source check.sh
source arvan.sh
source interaction.sh
fncGetInteraction
source pkg.sh
source config.sh
source internal.sh
source external.sh

if [[ "$_ARVAN_OR_NOT" == "yes" ]]; then
		fncArvanSetupVM
		exit 0
fi

if [[ "$_BOTH_OR_EXTERNAL" == "external" ]]; then
	echo ""
	echo "Script is running only for external server"
	echo ""
else
	fncInstallInternal
	fncSetupInternal
fi
fncInstallExternal
fncSetupExternalCommon

case "$_VPN_SERVICE" in
  "shadowsocks+obfs")
		fncSetupExternalShadowsocks		
    ;;
  "v2ray+vmess")
		fncSetupExternalV2rayVmess
    ;;
  "v2ray+vmess+ws")
		fncSetupExternalV2rayVmessWs
    ;;
  "trojan")
		fncSetupExternalTrojan
    ;;
esac

