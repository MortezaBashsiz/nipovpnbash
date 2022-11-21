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
source interaction.sh
fncGetInteraction
source pkg.sh
source config.sh
source internal.sh
source external.sh

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

# ---------- Select service with number (There is no need to type) ------ 
PS3="Choose Your Desired Service: "
VPNS=("shadowsocks+obfs" "v2ray+vmess" "v2ray+vmess+ws" "trojan" "Quit")

select _VPN_SERVICE in "${VPNS[@]}"
do
	case "$_VPN_SERVICE" in
		"shadowsocks+obfs")
			fncSetupExternalShadowsocks	
			break
      ;;
    "v2ray+vmess")
		  fncSetupExternalV2rayVmess
			break
      ;;
    "v2ray+vmess+ws")
	  	fncSetupExternalV2rayVmessWs
			break
      ;;
    "trojan")
	  	fncSetupExternalTrojan
			break
      ;;
		"Quit")
			exit 1
			;;
		*)
			echo "Choose one of the above! $REPLY"
  esac
done

