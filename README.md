# What is this?

This is an easy installation script to help you config these VPN protocols on your VPS.

- shadowsocks+obfs
- v2ray+vmess
- v2ray+vmess+ws
- trojan

# Requirements

1. an external VPS (outside Iran)
2. an internal VPS (Inside Iran) This is optional and you can use it for only external
3. Debian 11 OR Ubuntu 20.04 as the OS of both VMs
4. Able to SSH without password to both internal and external server

# How to setup ssh key on client

Your client (where the script will be executed), must be able to ssh without password and with ssh-key.
To do this, you need to create ssh key if you do not have in your client. With following command you can create ssh-key in your client

```bash
[~]>$ ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/home/morteza/.ssh/id_rsa):
.........
```

Then you need to copy the generated ssh key to the destination hosts with the following command 
```bash
[~]>$ ssh-copy-id root@192.168.5.10
```

A video guide on the usage can be found in [youtube](https://youtu.be/jO-1O1BJ6rE "youtube").

# How to Run
1. Download or clone the project
2. Go the the directory

```bash
[~/data/git/MortezaBashsiz/nipovpn/scripts]>$ ls -l
total 36
-rw-r--r-- 1 morteza morteza 1763 Nov  1 10:56 basic.sh
-rw-r--r-- 1 morteza morteza 1186 Oct 31 13:30 check.sh
-rw-r--r-- 1 morteza morteza 5037 Oct 31 14:52 external.sh
-rw-r--r-- 1 morteza morteza 2599 Oct 31 14:48 interaction.sh
-rw-r--r-- 1 morteza morteza 2867 Oct 31 14:41 internal.sh
-rw-r--r-- 1 morteza morteza  982 Nov  1 10:59 nipovpn.sh
-rw-r--r-- 1 morteza morteza 1334 Oct 31 11:54 pkg.sh
-rw-r--r-- 1 morteza morteza  447 Nov  1 11:14 README.md
[~/data/git/MortezaBashsiz/nipovpn/scripts]>$
```

3. Execute the nipovpn.sh and answer the questions like following

```bash
[~/data/git/MortezaBashsiz/nipovpn/scripts]>$ bash nipovpn.sh 

>Welcome to nipovpn 
>Please answer to the following questions 
>This script by default uses for setting up internal and external servers 
>How do you want to use this script? 
>Please choose from following or leave empty and push enter button for continue 
>> external
>> both
both
>Please answer to the following questions 
>Internal server IP address IP.IP.IP.IP
65.21.189.183
>SSH port for internal server 65.21.189.183 (default 22)
22
>Internal server port (default 443)
445
>External server IP address IP.IP.IP.IP
65.108.221.16
>SSH port for external server 65.108.221.16 (default 22)
22
>External server port (default 443)
445
>What kind of service would you like to use?
>These are the type of services which is supported by this script
>> shadowsocks+obfs
>> v2ray+vmess
>> v2ray+vmess+ws
>> trojan
>What kind of service would you like to use?(choose from list above)
v2ray+vmess
>Installing packages htop net-tools iptables-persistent vim fail2ban
Get:1 http://security.debian.org/debian-security bullseye-security InRelease [48.4 kB]
Get:2 http://deb.debian.org/debian bullseye InRelease [116 kB]
Get:3 http://deb.debian.org/debian bullseye-updates InRelease [44.1 kB]
```

Video link in [youtube](https://youtu.be/jO-1O1BJ6rE "youtube") 

