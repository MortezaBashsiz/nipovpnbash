#!/bin/bash  -
#===============================================================================
#
#          FILE: arvan.sh
#
#         USAGE: ./arvan.sh
#
#   DESCRIPTION: 
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Morteza Bashsiz (mb), morteza.bashsiz@gmail.com
#  ORGANIZATION: Linux
#       CREATED: 12/18/2022 08:05:49 PM
#      REVISION:  ---
#===============================================================================

set -o nounset                                  # Treat unset variables as an error

cdnApiUrl="https://napi.arvancloud.ir/cdn/4.0"

# Function fncArvanGetDomainsList
# Prints Domains List
function fncArvanGetDomainsList {
	domainsList=$(curl -s -XGET -H "Authorization: $_ARVAN_API_KEY" -H "Content-Type: application/json" "$cdnApiUrl"/domains | jq .data[].domain)
	echo "$domainsList"
}
# End of Function fncArvanGetDomainsList

# Function fncArvanGetDomainInfo
# Get Domain Info
function fncArvanGetDomainInfo {
	local domainName="$1"
	local result
	result=$(curl -s -XGET -H "Authorization: $_ARVAN_API_KEY" -H "Content-Type: application/json" "$cdnApiUrl"/domains/"$domainName" | jq .data 2>/dev/null)
	echo "$result"
}
# End of Function fncArvanGetDomainInfo

# Function fncArvanGetDomainRecords
# Get Domain Records
function fncArvanGetDomainRecords {
	local domainName="$1"
	local result
	result=$(curl -s -XGET -H "Authorization: $_ARVAN_API_KEY" -H "Content-Type: application/json" "$cdnApiUrl"/domains/"$domainName"/dns-records | jq .data[].name 2>/dev/null)
	echo "$result"
}
# End of Function fncArvanGetDomainRecords

# Function fncArvanGetDomainNS
# Return Domain NS records
function fncArvanGetDomainNS {
	local domainName="$1"
	local result domainInfo
	domainInfo=$(fncArvanGetDomainInfo "$domainName")
	result=$(echo "$domainInfo" | jq .ns_keys[])
	echo "$result"
}
# End of Function fncArvanGetDomainNS

# Function fncArvanGetDomainStatus
# Check domain status return true or false
function fncArvanGetDomainStatus {
	local domainName="$1"
	local result domainInfo
	domainInfo=$(fncArvanGetDomainInfo "$domainName")
	result=$(echo "$domainInfo" | jq .status)
	if [[ "$result" == "\"active\"" ]]
	then
		echo "true"
		return 0
	else
		echo "false"
		return 1
	fi
}
# End of Function fncArvanGetDomainStatus

# Function fncArvanCreateDomain
# Create Domain return true or false
function fncArvanCreateDomain {
	local domainName="$1"
	local domainInfo domainId result
	currentDomains=$(fncArvanGetDomainsList)
	# shellcheck disable=SC2068
	for item in ${currentDomains[@]} 
	do
		if [[ "$item" == "\"$domainName\"" ]];
		then
			echo "true"
			return 0
		fi
	done
	sleep 5
	domainJson="{ \"domain\": \"$domainName\", \"domain_type\": \"full\", \"plan_level\": 1 }"
	result=$(curl -s -XPOST -H "Authorization: $_ARVAN_API_KEY" -H "Content-Type: application/json" -d "$domainJson" "$cdnApiUrl"/domains/dns-service)
	currentDomains=$(fncArvanGetDomainsList)
	# shellcheck disable=SC2068
	for item in ${currentDomains[@]} 
	do
		if [[ "$item" == "\"$domainName\"" ]];
		then
			echo "true"
			return 0
		fi
	done
	echo "false"
	return 1
}
# End of Function fncArvanCreateDomain

# Function fncArvanDeleteDomain
# Delete Domain and retunr true or false
function fncArvanDeleteDomain {
	local domainName="$1"
	local domainInfo domainId result
	currentDomains=$(fncArvanGetDomainsList)
	# shellcheck disable=SC2068
	for item in ${currentDomains[@]}
	do
		if [[ "$item" == "\"$domainName\"" ]];
		then
			domainInfo=$(fncArvanGetDomainInfo "$domainName")
			domainId=$(echo "$domainInfo" | jq .id)
			local deleteDomainJson="{ \"id\": $domainId }"
			result=$(curl -s -XDELETE -H "Authorization: $_ARVAN_API_KEY" -H "Content-Type: application/json" -d "$deleteDomainJson" "$cdnApiUrl"/domains/"$domainName")
		fi
	done
	sleep 5
	currentDomains=$(fncArvanGetDomainsList)
	# shellcheck disable=SC2068
	for item in ${currentDomains[@]}
	do
		if [[ "$item" == "\"$domainName\"" ]];
		then
			echo "false"
			return 1
		fi
	done
	echo true
	return 0
}
# End of Function fncArvanDeleteDomain

# Function fncArvanCreateARecord
# Creates Record and return true or false 
function fncArvanCreateARecord {
	local resultARecord 
	local domainName="$1"
	local recordName="$2"
	local recordIp="$3"
	currentRecords=$(fncArvanGetDomainRecords "$domainName")
	# shellcheck disable=SC2068
	for item in ${currentRecords[@]}
	do
		if [[ "$item" == "\"$recordName\"" ]];
		then
			echo "true"
			return 0
		fi
	done
	local aRecordJson="{ \"type\": \"a\", \"name\": \"$recordName\", \"value\": [{ \"ip\": \"$recordIp\" }], \"ttl\": 120, \"cloud\": false, \"upstream_https\": \"https\", \"ip_filter_mode\": { \"count\": \"single\", \"order\": \"none\", \"geo_filter\": \"none\" }}"
	resultARecord=$(curl -s -XPOST -H "Authorization: $_ARVAN_API_KEY" -H "Content-Type: application/json" -d "$aRecordJson" "$cdnApiUrl"/domains/"$domainName"/dns-records)
	sleep 5
	currentRecords=$(fncArvanGetDomainRecords "$domainName")
	# shellcheck disable=SC2068
	for item in ${currentRecords[@]}
	do
		if [[ "$item" == "\"$recordName\"" ]];
		then
			echo "true"
			return 0
		fi
	done
	echo "false"
	return 1
}
# End of Function fncArvanCreateARecord

# Function fncArvanCreateCnameRecord
# Creates record and return true or false 
function fncArvanCreateCnameRecord {
	local resultCnameRecord currentRecords
	local domainName="$1"
	local recordName="$2"
	currentRecords=$(fncArvanGetDomainRecords "$domainName")
	# shellcheck disable=SC2068
	for item in ${currentRecords[@]}
	do
		if [[ "$item" == "\"gheychi$recordName\"" ]];
		then
			echo "true"
			return 0
		fi
	done
	local cnameRecordJson="{ \"type\": \"cname\", \"name\": \"gheychi$recordName\", \"value\": { \"host\": \"$recordName.$domainName.\" }, \"ttl\": 120, \"cloud\": true, \"upstream_https\": \"default\", \"ip_filter_mode\": { \"count\": \"single\", \"order\": \"none\", \"geo_filter\": \"none\" }}"
	resultCnameRecord=$(curl -s -XPOST -H "Authorization: $_ARVAN_API_KEY" -H "Content-Type: application/json" -d "$cnameRecordJson" "$cdnApiUrl"/domains/"$domainName"/dns-records)
	sleep 5	
	currentRecords=$(fncArvanGetDomainRecords "$domainName")
	# shellcheck disable=SC2068
	for item in ${currentRecords[@]}
	do
		if [[ "$item" == "\"gheychi$recordName\"" ]];
		then
			echo "true"
			return 0
		fi
	done
	echo "false"
	return 1
}
# End of Function fncArvanCreateCnameRecord

# Function fncArvanCreateCloudRecord
# Creates Cloud ns record and return true or false
function fncArvanCreateCloudRecord {
	local resultARecord resultCnameRecord 
	local domainName="$1"
	local recordName="$2"
	local recordIp="$3"
	resultARecord=$(fncArvanCreateARecord "$domainName" "$recordName" "$recordIp")
	resultCnameRecord=$(fncArvanCreateCnameRecord "$domainName" "$recordName")
	if [[ "$resultARecord" == "true" ]] && [[ "$resultCnameRecord" == "true" ]];
	then
		echo "true"
		return 0
	else
		echo "false"
		return 1
	fi
}
# End of Function fncArvanCreateCloudRecord

# Function fncArvanCheckApiKey
# Check ApiKey
function fncArvanCheckApiKey {
	local resultApiKey
	resultApiKey=$(curl -s -XGET -H "Authorization: $_ARVAN_API_KEY"  "$cdnApiUrl"/domains | grep -i "unauthenticated")
	if [[ "$resultApiKey" ]]
	then
		fncExitErr "Token is not correct, Unaithenticated"
	fi
}
# End of Function fncArvanCheckApiKey

# Function fncArvanCheckDomain
# Check Domain
function fncArvanCheckDomain {
	local resultDomain
	resultDomain=$(fncArvanCreateDomain "$_ARVAN_DOMAIN")	
	if [[ "$resultDomain" != "true" ]]
	then
		fncExitErr "Domain creation faild"
	fi
}
# End of Function fncArvanCheckDomain


# Function fncArvanCheckDomainStatus
# Check Domain Status
function fncArvanCheckDomainStatus {
	local resultDomain
	resultDomain=$(fncArvanGetDomainStatus "$_ARVAN_DOMAIN")	
	if [[ "$resultDomain" != "true" ]]
	then
		fncExitErr "Domain Is not activated. You have to change the ns records in your domain provider. If you already did it please try later"
	fi
}
# End of Function fncArvanCheckDomainStatus

# Function fncArvanCeckCloudRecord
# Check Domain Status
function fncArvanCeckCloudRecord {
	local resultCloudRecord ip
	ip="$1"
	resultCloudRecord=$(fncArvanCreateCloudRecord "$_ARVAN_DOMAIN" "vpn" "$ip" )	
	if [[ "$resultCloudRecord" != "true" ]]
	then
		fncExitErr "Record is not created"
	fi
}
# End of Function fncArvanCeckCloudRecord

# Function fncArvanVMCommon
# Setup Arvan VM common 
function fncArvanVMCommon {
	scp -r -P "$_ARVAN_VM_SSH_PORT" ../tools root@"$_ARVAN_VM_IP":/opt/
	echo "${_ARVAN_VM_IPTABLES_CFG}" > /tmp/arvan_iptables
	scp -r -P "$_ARVAN_VM_SSH_PORT" /tmp/arvan_iptables root@"$_ARVAN_VM_IP":/root/
	fncExecCmd "$_ARVAN_VM_IP" "$_ARVAN_VM_SSH_PORT" "mv /root/arvan_iptables /etc/iptables/rules.v4"
	fncExecCmd "$_ARVAN_VM_IP" "$_ARVAN_VM_SSH_PORT" "systemctl restart iptables.service; systemctl enable iptables.service;"
	echo "${_ARVAN_FAIL2BAN_CFG}" > /tmp/arvan_fail2ban
	scp -r -P "$_ARVAN_VM_SSH_PORT" /tmp/arvan_fail2ban root@"$_ARVAN_VM_IP":/root/
	fncExecCmd "$_ARVAN_VM_IP" "$_ARVAN_VM_SSH_PORT" "mv /root/arvan_fail2ban /etc/fail2ban/jail.d/sshd.conf"
	fncExecCmd "$_ARVAN_VM_IP" "$_ARVAN_VM_SSH_PORT" "systemctl restart fail2ban.service; systemctl enable fail2ban.service;"
}
# End of Function fncArvanVMCommon

# Function fncArvanSetupV2raySystemd
# Setup external host 
function fncArvanSetupV2raySystemd {
	if [[ "$_DIST" == "UBUNTU" ]]; then
		echo "${_ARVAN_V2RAY_VMESS_SYSTEMD_CFG}" > /tmp/arvan_v2rayvmess_systemd
		scp -r -P "$_ARVAN_VM_SSH_PORT" /tmp/arvan_v2rayvmess_systemd root@"$_ARVAN_VM_IP":/root/
		fncExecCmd "$_ARVAN_VM_IP" "$_ARVAN_VM_SSH_PORT" "mkdir -p /etc/systemd/system/v2ray.service.d"
		fncExecCmd "$_ARVAN_VM_IP" "$_ARVAN_VM_SSH_PORT" "mv /root/arvan_v2rayvmess_systemd /etc/systemd/system/v2ray.service.d/v2ray.conf"
	fi
}
# End of Function fncArvanSetupV2raySystemd

# Function fncArvanInstall
# Installs the packages on external host
function fncArvanInstall {
	if [[ "$_DIST" == "UBUNTU" ]]; then
		fncPkgInstall "$_ARVAN_VM_IP" "$_ARVAN_VM_SSH_PORT" "gnupg ca-certificates curl python3-certbot-nginx certbot"
		fncExecCmd "$_ARVAN_VM_IP" "$_ARVAN_VM_SSH_PORT" "curl -sSL https://apt.v2fly.org/pubkey.gpg | sudo apt-key add -"
		fncExecCmd "$_ARVAN_VM_IP" "$_ARVAN_VM_SSH_PORT" "echo \"deb [arch=amd64] https://apt.v2fly.org/ stable main\" | sudo tee /etc/apt/sources.list.d/v2ray.list"
	fi
	fncPkgInstall "$_ARVAN_VM_IP" "$_ARVAN_VM_SSH_PORT" "iptables-persistent"
	fncPkgInstall "$_ARVAN_VM_IP" "$_ARVAN_VM_SSH_PORT" "htop net-tools vim fail2ban"
	fncPkgInstall "$_ARVAN_VM_IP" "$_ARVAN_VM_SSH_PORT" "python3-urllib3 v2ray nginx certbot python3-certbot-nginx"
}
# End of Function fncArvanInstall

# Function fncArvanSetupVM
# Setup Arvan host with V2ray Vmess WS Nginx
function fncArvanSetupVM {
	fncArvanInstall
	fncArvanVMCommon
	fncArvanSetupV2raySystemd
	fncExecCmd "$_ARVAN_VM_IP" "$_ARVAN_VM_SSH_PORT" "iptables -F"
	fncExecCmd "$_ARVAN_VM_IP" "$_ARVAN_VM_SSH_PORT" "systemctl stop nginx"
	fncExecCmd "$_ARVAN_VM_IP" "$_ARVAN_VM_SSH_PORT" "certbot certonly --standalone --preferred-challenges http -d vpn.$_ARVAN_DOMAIN --non-interactive --agree-tos -m admin@$_ARVAN_DOMAIN"
	fncExecCmd "$_ARVAN_VM_IP" "$_ARVAN_VM_SSH_PORT" "systemctl start nginx"
	fncExecCmd "$_ARVAN_VM_IP" "$_ARVAN_VM_SSH_PORT" "systemctl restart iptables"
	echo "${_ARVAN_V2RAY_CFG}" > /tmp/arvan_v2rayvmessws
	scp -r -P "$_ARVAN_VM_SSH_PORT" /tmp/arvan_v2rayvmessws root@"$_ARVAN_VM_IP":/root/
	fncExecCmd "$_ARVAN_VM_IP" "$_ARVAN_VM_SSH_PORT" "mv /root/arvan_v2rayvmessws /etc/v2ray/config.json"
	fncExecCmd "$_ARVAN_VM_IP" "$_ARVAN_VM_SSH_PORT" "systemctl daemon-reload; systemctl restart v2ray.service; systemctl enable v2ray.service;"
	echo "${_ARVAN_NGINX_CFG}" > /tmp/arvan_v2rayvmesswsnginx
	scp -r -P "$_ARVAN_VM_SSH_PORT" /tmp/arvan_v2rayvmesswsnginx root@"$_ARVAN_VM_IP":/root/
	fncExecCmd "$_ARVAN_VM_IP" "$_ARVAN_VM_SSH_PORT" "mv /root/arvan_v2rayvmesswsnginx /etc/nginx/nginx.conf"
	fncExecCmd "$_ARVAN_VM_IP" "$_ARVAN_VM_SSH_PORT" "systemctl restart nginx.service; systemctl enable nginx.service;"
	fncExecCmd "$_ARVAN_VM_IP" "$_ARVAN_VM_SSH_PORT" "python3 /opt/tools/conf2vmess.py -c /etc/v2ray/config.json -s gheychivpn.$_ARVAN_DOMAIN -p 443 -o /opt/tools/output-vmess.json"
	fncExecCmd "$_ARVAN_VM_IP" "$_ARVAN_VM_SSH_PORT" "sed -i 's/\"tls\": \"none\"/\"tls\": \"tls\"/g' /opt/tools/output-vmess.json"
	fncExecCmd "$_ARVAN_VM_IP" "$_ARVAN_VM_SSH_PORT" "python3 /opt/tools/vmess2sub.py /opt/tools/output-vmess.json /opt/tools/output-vmess_v2rayN.html -l /opt/tools/output-vmess_v2rayN.lnk"
	_vmessurl=$(fncExecCmd "$_ARVAN_VM_IP" "$_ARVAN_VM_SSH_PORT" "cat /opt/tools/output-vmess_v2rayN.lnk")
	echo ""
	echo "> Your VMESS url is as following inport it to your client device"
	echo "$_vmessurl"
}
# End of Function fncArvanSetupVM

