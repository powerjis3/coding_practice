#!/bin/bash

## hostname setting
echo -n "hostname setting : "
read HOSTNAME
hostnamectl set-hostname --static $HOSTNAME

## ipv6 disable - grub
sed -i 
update-grub

## ssh port setting
sed -i 's/.*Port 22$/Port 2222/g' /etc/ssh/sshd_config

## package install & update
apt-get update
apt-get install -y vim curl dmidecode gcc  lsof man rsync strace sysstat unzip vim wget zip net-tools telnet

## ntp setting
sed -i ' ' /etc/systemd/timesyncd.conf
systemctl restart systemd-timesyncd.service

## zabbix agent install & setting


## filebeat install & setting

## ssh setting
echo -e '\nAllowUsers daesukim@172.30.12.41 yoin@172.30.12.43 mcon@172.30.12.42 hyeonshin@172.30.12.40' >> /etc/ssh/sshd_config
sed -i 's/.*PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
systemctl restart sshd.service

## ad setting & reboot

