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
	tmpDist=$(fncExecCmd "$ip" "$port" "grep Debian /etc/issue")
	if [[ "$tmpDist" == "Debian GNU/Linux 11 \\n \\l" ]]; then
		_DIST="DEBIAN"
	fi
}
# End of Function fncGetDistro

# Function fncGetDistro
# Change $_DIST to DEBIAN if Linux distro is Debina
function fncCheckDistro {
	ip="$1"
	port="$2"
	fncGetDistro "$ip" "$port"
	if [[ "$_DIST" != "DEBIAN" ]]; then
		fncExitErr "THIS SCRIPT ONLY WORKS ON DEBIAN 11"
	fi
}
# End of Function fncGetDistro


