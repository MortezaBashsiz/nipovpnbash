#!/bin/bash  -
#===============================================================================
#
#          FILE: internal.sh
#
#         USAGE: ./internal.sh
#
#   DESCRIPTION: 
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Morteza Bashsiz (mb), morteza.bashsiz@gmail.com
#  ORGANIZATION: Linux
#       CREATED: 10/30/2022 08:48:33 PM
#      REVISION:  ---
#===============================================================================

set -o nounset                                  # Treat unset variables as an error

# Function fncSetupInternal
# Setup external host
function fncSetupInternal {
	echo "${_INTERNAL_IPTABLES_CFG}" > /tmp/internal_iptables
	scp -r -P "$_INTERNAL_SSH_PORT" /tmp/internal_iptables root@"$_INTERNAL_IP":/root/
	fncExecCmd "$_INTERNAL_IP" "$_INTERNAL_SSH_PORT" "cp /root/internal_iptables /etc/iptables/rules.v4"
	fncExecCmd "$_INTERNAL_IP" "$_INTERNAL_SSH_PORT" "systemctl restart iptables.service; systemctl enable iptables.service;"
	echo "${_FAIL2BAN_CFG}" > /tmp/internal_fail2ban
	scp -r -P "$_INTERNAL_SSH_PORT" /tmp/internal_fail2ban root@"$_INTERNAL_IP":/root/
	fncExecCmd "$_INTERNAL_IP" "$_INTERNAL_SSH_PORT" "cp /root/internal_fail2ban /etc/fail2ban/jail.d/sshd.conf"
	fncExecCmd "$_INTERNAL_IP" "$_INTERNAL_SSH_PORT" "systemctl restart fail2ban.service; systemctl enable fail2ban.service;"
	echo "${_INTERNAL_IP}" > /tmp/internal_sysctl
	scp -r -P "$_INTERNAL_SSH_PORT" /tmp/internal_sysctl root@"$_INTERNAL_IP":/root/
	fncExecCmd "$_INTERNAL_IP" "$_INTERNAL_SSH_PORT" "cp /root/internal_sysctl /etc/sysctl.d/99-sysctl.conf"
	fncExecCmd "$_INTERNAL_IP" "$_INTERNAL_SSH_PORT" "sysctl -w net.ipv4.ip_forward=1"
}
# End of Function fncSetupInternal

