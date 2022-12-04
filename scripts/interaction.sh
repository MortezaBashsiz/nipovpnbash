#!/bin/bash  -
#===============================================================================
#
#          FILE: interaction.sh
#
#         USAGE: ./interaction.sh
#
#   DESCRIPTION: 
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Morteza Bashsiz (mb), morteza.bashsiz@gmail.com
#  ORGANIZATION: Linux
#       CREATED: 10/31/2022 08:55:28 AM
#      REVISION:  ---
#===============================================================================

set -o nounset                                  # Treat unset variables as an error

_BOTH_OR_EXTERNAL_ARR=(
											"both"
											"external"
											)
_BOTH_OR_EXTERNAL="both"

_INTERNAL_IP="NULL"
_INTERNAL_SSH_PORT="22"
_INTERNAL_VPN_PORT="443"

_EXTERNAL_IP="NULL"
_EXTERNAL_SSH_PORT="22"
_EXTERNAL_VPN_PORT="443"

_VPN_SERVICE_LIST=(
									"shadowsocks+obfs"
									"v2ray+vmess"
									"v2ray+vmess+ws"
									"trojan"
									)
_VPN_SERVICE="NULL"

# Function fncGetInteraction
# Get data from cmd input
function fncGetInteraction {
	echo ""
	echo "> Welcome to nipovpn "
	echo "> Please answer to the following questions "
	echo "> This script by default uses for setting up internal and external servers "
	echo "> How do you want to use this script? "
	echo "> Please choose from following or leave empty and push enter button for continue (ENTER THE NUMBER)"
	select opt in "${_BOTH_OR_EXTERNAL_ARR[@]}"
	do
		case $opt in
			"external")
				_BOTH_OR_EXTERNAL="external"
			  break
			  ;;
			"both")
				_BOTH_OR_EXTERNAL="both"
			  break
			  ;;
			*) echo "invalid option $REPLY";;
		esac
	done
	if [[ "$_BOTH_OR_EXTERNAL" == "both" ]]; then
		echo "> Internal server IP address IP.IP.IP.IP"
		read -r tmpInput
		if [[ "$tmpInput" ]]; then
			_INTERNAL_IP="$tmpInput"
		else
			fncExitErr "internal server IP can not be empty"
		fi
		echo "> SSH port for internal server $_INTERNAL_IP (default 22)"
		read -r tmpInput
		if [[ "$tmpInput" ]]; then
			_INTERNAL_SSH_PORT=$tmpInput
		fi
		fncCheckSSH "$_INTERNAL_IP" "$_INTERNAL_SSH_PORT"
		fncCheckDistro "$_INTERNAL_IP" "$_INTERNAL_SSH_PORT"
		echo "> Internal server port (default 443)"
		read -r tmpInput
		if [[ "$tmpInput" ]]; then
			_INTERNAL_VPN_PORT=$tmpInput
		fi
	fi
	echo "> External server IP address IP.IP.IP.IP"
	read -r tmpInput
	if [[ "$tmpInput" ]]; then
		_EXTERNAL_IP="$tmpInput"
	else
		fncExitErr "external server IP can not be empty"
	fi
	echo "> SSH port for external server $_EXTERNAL_IP (default 22)"
	read -r tmpInput
	if [[ "$tmpInput" ]]; then
		_EXTERNAL_SSH_PORT="$tmpInput"
	fi
	fncCheckSSH "$_EXTERNAL_IP" "$_EXTERNAL_SSH_PORT"
	fncCheckDistro "$_EXTERNAL_IP" "$_EXTERNAL_SSH_PORT"
	echo "> External server port (default 443)"
	read -r tmpInput
	if [[ "$tmpInput" ]]; then
		_EXTERNAL_VPN_PORT=$tmpInput
	fi
	echo "> What kind of service would you like to use?"
	echo "> These are the type of services which is supported by this script (ENTER THE NUMBER)"
	select opt in "${_VPN_SERVICE_LIST[@]}"
	do
		case $opt in
			"shadowsocks+obfs")
				_VPN_SERVICE="shadowsocks+obfs"
			  break
			  ;;
			"v2ray+vmess")
				_VPN_SERVICE="v2ray+vmess"
			  break
			  ;;
			"v2ray+vmess+ws")
				_VPN_SERVICE="v2ray+vmess+ws"
			  break
			  ;;
			"trojan")
				_VPN_SERVICE="trojan"
			  break
			  ;;
			*) echo "invalid option $REPLY";;
		esac
	done
}
# End of Function fncGetInteraction

