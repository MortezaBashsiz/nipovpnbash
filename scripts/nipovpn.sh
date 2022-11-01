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
source internal.sh
source external.sh

fncInstallInternal
fncInstallExternal
fncSetupExternalCommon

case "$_VPN_SERVICE" in
  "shadowsocks+obfs")
		fncSetupInternal
		fncSetupExternalShadowsocks		
    ;;

  "v2ray+vmess")
		fncSetupInternal
		fncSetupExternalV2rayVmess
    ;;
esac

