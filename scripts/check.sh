#!/bin/bash  -
#===============================================================================
#
#          FILE: check.sh
#
#         USAGE: ./check.sh
#
#   DESCRIPTION: 
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Morteza Bashsiz (mb), morteza.bashsiz@gmail.com
#  ORGANIZATION: Linux
#       CREATED: 10/30/2022 08:48:02 PM
#      REVISION:  ---
#===============================================================================

set -o nounset                                  # Treat unset variables as an error

_DIST="UNKNOWN"

# Function fncGetDistro
# Change $_DIST to DEBIAN if Linux distro is Debina
function fncGetDistro {
	local tmpDist=""
	ip="$1"
	port="$2"
	tmpDist=$(fncExecCmd "$ip" "$port" "cat /etc/issue")
	if [[ "$tmpDist" == *"Debian"* ]]; then
		_DIST="DEBIAN"
	elif [[ "$tmpDist" == *"Ubuntu"* ]]; then
		_DIST="UBUNTU"
	fi
}
# End of Function fncGetDistro

# Function fncGetDistro
# Change $_DIST to DEBIAN if Linux distro is Debina
function fncCheckDistro {
	ip="$1"
	port="$2"
	fncGetDistro "$ip" "$port"
	if [[ "$_DIST" == "DEBIAN" ]]; then
		echo "> Installing for Debian"
	elif [[ "$_DIST" == "UBUNTU" ]]; then
		echo "> Installing for Ubuntu"
	else
		fncExitErr "THIS SCRIPT ONLY WORKS ON DEBIAN 11 or UBUNTU 20.04"
	fi
}
# End of Function fncGetDistro


