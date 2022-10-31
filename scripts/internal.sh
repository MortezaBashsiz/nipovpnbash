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

_INTERNAL_IPTABLES_CFG=$(cat << EOF
*filter
:INPUT ACCEPT [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -d $_INTERNAL_IP/32 -p udp -m udp --dport $_INTERNAL_VPN_PORT -j ACCEPT
-A INPUT -d $_INTERNAL_IP/32 -p tcp -m tcp --dport $_INTERNAL_VPN_PORT -j ACCEPT
-A INPUT -p tcp -m tcp --dport $_INTERNAL_SSH_PORT -j ACCEPT
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -j DROP
-A FORWARD -d $_EXTERNAL_IP/32 -j ACCEPT
-A FORWARD -s $_EXTERNAL_IP/32 -j ACCEPT
-A FORWARD -j DROP
-A OUTPUT -j ACCEPT
COMMIT
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A PREROUTING -d $_INTERNAL_IP/32 -p udp -m udp --dport $_INTERNAL_VPN_PORT -j DNAT --to-destination $_EXTERNAL_IP:$_EXTERNAL_VPN_PORT 
-A PREROUTING -d $_INTERNAL_IP/32 -p tcp -m tcp --dport $_INTERNAL_VPN_PORT -j DNAT --to-destination $_EXTERNAL_IP:$_EXTERNAL_VPN_PORT
-A POSTROUTING -j MASQUERADE
COMMIT
EOF
)

_FAIL2BAN_CFG=$(cat << EOF
[sshd]
enabled = true
bantime = 15m
findtime = 10m
maxretry = 3
EOF
)

_SYSCTL_CFG="net.ipv4.ip_forward = 1"

# Function fncSetupInternal
# Setup external host
function fncSetupInternal {
	echo "${_INTERNAL_IPTABLES_CFG}" > /tmp/internal_iptables
	scp -r -P "$_INTERNAL_SSH_PORT" /tmp/internal_iptables "$_INTERNAL_IP":/root/
	fncExecCmd "$_INTERNAL_IP" "$_INTERNAL_SSH_PORT" "cp /root/internal_iptables /etc/iptables/rules.v4"
	fncExecCmd "$_INTERNAL_IP" "$_INTERNAL_SSH_PORT" "systemctl restart iptables.service; systemctl enable iptables.service;"
	echo "${_FAIL2BAN_CFG}" > /tmp/internal_fail2ban
	scp -r -P "$_INTERNAL_SSH_PORT" /tmp/internal_fail2ban "$_INTERNAL_IP":/root/
	fncExecCmd "$_INTERNAL_IP" "$_INTERNAL_SSH_PORT" "cp /root/internal_fail2ban /etc/fail2ban/jail.d/sshd.conf"
	fncExecCmd "$_INTERNAL_IP" "$_INTERNAL_SSH_PORT" "systemctl restart fail2ban.service; systemctl enable fail2ban.service;"
	echo "${_INTERNAL_IP}" > /tmp/internal_sysctl
	scp -r -P "$_INTERNAL_SSH_PORT" /tmp/internal_sysctl "$_INTERNAL_IP":/root/
	fncExecCmd "$_INTERNAL_IP" "$_INTERNAL_SSH_PORT" "cp /root/internal_sysctl /etc/sysctl.d/99-sysctl.conf"
	fncExecCmd "$_INTERNAL_IP" "$_INTERNAL_SSH_PORT" "sysctl -w net.ipv4.ip_forward=1"
}
# End of Function fncSetupInternal

