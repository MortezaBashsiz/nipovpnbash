#!/bin/bash  -
#===============================================================================
#
#          FILE: basic.sh
#
#         USAGE: ./basic.sh
#
#   DESCRIPTION: 
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Morteza Bashsiz (mb), morteza.bashsiz@gmail.com
#  ORGANIZATION: Linux
#       CREATED: 10/30/2022 09:06:27 PM
#      REVISION:  ---
#===============================================================================

set -o nounset                                  # Treat unset variables as an error

# Function fncExtiErr
# Print Error and exit with code 1
function fncExitErr {
	local msg="$1"
	echo ERR: "$msg"
	exit 1
}
# End of Function fncExitErr

# Function fncCheckSSH
# checks the ssh login
function fncCheckSSH {
	local ip="$1"
	local port="$2"
	ssh -q -o BatchMode=yes  -o StrictHostKeyChecking=no "$ip" -l root -p "$port" 'exit 0'
	local rcode=$?
	if [[ "$rcode" != "0" ]]; then
		fncExitErr "SSH connectivity is not OK with user root to IP $ip and port $port"
	fi
}
# End of Function fncCheckSSH

# Function fncPkgInstall
# Install packages on destination host
function fncPkgInstall {
	local ip="$1"
	local port="$2"
	local pkglist="$3"
	fncCheckSSH "$ip" "$port"
	echo "> Installing packages $pkglist"
	ssh -q -o BatchMode=yes  -o StrictHostKeyChecking=no "$ip" -l root -p "$port" "export DEBIAN_FRONTEND=noninteractive ;apt-get --yes --assume-yes update; apt-get --yes --assume-yes install $pkglist"
}
# End of Function fncPkgInstall

# Function fncExecCmd
# Execute command on destination host
function fncExecCmd {
	local ip="$1"
	local port="$2"
	local cmd="$3"
	fncCheckSSH "$ip" "$port"
	result=$(ssh -q -o BatchMode=yes  -o StrictHostKeyChecking=no "$ip" -l root -p "$port" "$cmd")
	echo "$result"
}
# End of Function fncExecCmd
