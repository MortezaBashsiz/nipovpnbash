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
	echo ">Welcome to nipovpn "
	echo ">Please answer to the following questions "
	echo ">Internal server IP address IP.IP.IP.IP"
	read -r tmpInput
	if [[ "$tmpInput" ]]; then
		_INTERNAL_IP="$tmpInput"
	else
		fncExitErr "internal server IP can not be empty"
	fi
	echo ">SSH port for internal server $_INTERNAL_IP (default 22)"
	read -r tmpInput
	if [[ "$tmpInput" ]]; then
		_INTERNAL_SSH_PORT=$tmpInput
	fi
	fncCheckSSH "$_INTERNAL_IP" "$_INTERNAL_SSH_PORT"
	fncCheckDistro "$_INTERNAL_IP" "$_INTERNAL_SSH_PORT"
	echo ">Internal server port (default 443)"
	read -r tmpInput
	if [[ "$tmpInput" ]]; then
		_INTERNAL_VPN_PORT=$tmpInput
	fi
	echo ">External server IP address IP.IP.IP.IP"
	read -r tmpInput
	if [[ "$tmpInput" ]]; then
		_EXTERNAL_IP="$tmpInput"
	else
		fncExitErr "external server IP can not be empty"
	fi
	echo ">SSH port for external server $_EXTERNAL_IP (default 22)"
	read -r tmpInput
	if [[ "$tmpInput" ]]; then
		_EXTERNAL_SSH_PORT="$tmpInput"
	fi
	fncCheckSSH "$_EXTERNAL_IP" "$_EXTERNAL_SSH_PORT"
	fncCheckDistro "$_EXTERNAL_IP" "$_EXTERNAL_SSH_PORT"
	echo ">External server port (default 443)"
	read -r tmpInput
	if [[ "$tmpInput" ]]; then
		_EXTERNAL_VPN_PORT=$tmpInput
	fi
	echo ">What kind of service would you like to use?"
	echo ">These are the type of services which is supported by this script"
	for item in "${_VPN_SERVICE_LIST[@]}"
	do
		echo ">> $item"
	done
	echo ">What kind of service would you like to use?(choose from list above)"
	read -r tmpInput
	if [[ "${_VPN_SERVICE_LIST[*]}" =~ "$tmpInput" ]]; then
		_VPN_SERVICE="$tmpInput"
	else
		fncExitErr "Selected service is not correct $tmpInput"
	fi
}
# End of Function fncGetInteraction

