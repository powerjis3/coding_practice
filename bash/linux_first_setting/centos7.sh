#!/bin/bash

## hostname setting
echo -n "hostname setting : "
read HOSTNAME
hostnamectl set-hostname --static $HOSTNAME

## ipv6 disable - grub
sed -i 's/quiet/ipv6.disable=1/' /etc/default/grub
grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
grub2-mkconfig -o /boot/grub2/grub.cfg

## selinux disabled
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

## crontab mail disable
sed -i 's/MAILTO.*/MAILTO=" "/g' /etc/crontab

## ssh port setting
sed -i 's/^.Port 22$/Port 2222/g' /etc/ssh/sshd_config

## don`t use daemon disable
systemctl disable firewalld NetworkManager postfix
systemctl stop firewalld NetworkManager postfix

## nameserver setting
cat <<EOF > /etc/resolv.conf
nameserver 110.45.202.241
nameserver 110.45.202.242
EOF

## package install & update
yum install -y bind-utils chrony curl dmidecode gcc libgcc lsof man openssh-clients rsync sos strace sysstat unzip vim wget zip net-tools telnet bash-completion
yum update -y

## historylog setting
cat <<EOF > /etc/profile.d/historylog.sh
#!/bin/bash
function history_to_syslog() {
  declare USERCMD
  USERCMD=\$(fc -ln -0 2>/dev/null|sed 's/\t //')
  declare PP
  if [ "\$USER" == "root" ];then
    PP="]#"
  else
    PP="]$"
  fi
  if [ "\$USERCMD" != "\$OLD_USERCMD" ];then
    logger -p local3.notice -t bash -i " \$USER\$(who am i|awk '{print \$NF}')\$SUDO_USER:\$PWD\$PP \$USERCMD"
  fi
  OLD_USERCMD=\$USERCMD
  unset USERCMD PP
}
trap 'history_to_syslog' DEBUG
EOF
sed -i 's/*.info;mail.none;authpriv.none;cron.none/*.info;mail.none;authpriv.none;cron.none;local3.none/g' /etc/rsyslog.conf
cat <<EOF >> /etc/rsyslog.conf

#### key logs
local3.*          /var/log/history.log
EOF
touch /var/log/history.log
systemctl restart rsyslog.service

## chrony setting
sed -i 's/^server/#server/' /etc/chrony.conf
echo 'server ntp.qoo10.jp' >> /etc/chrony.conf
systemctl restart chronyd.service

## zabbix agent install & setting
wget https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-agent-4.4.10-1.el7.x86_64.rpm
yum install -y ~/zabbix-agent-4.4.10-1.el7.x86_64.rpm
wget http://jpsysgit.qoo10jp.net/jpsysadmin/public_share/raw/master/Zabbix_Agent_Linux/ebay.conf -P /etc/zabbix/zabbix_agentd.d/
sed -i "s/^Hostname.*/Hostname=$HOSTNAME/g" /etc/zabbix/zabbix_agentd.conf
systemctl enable zabbix-agent.service
systemctl start zabbix-agent.service

## filebeat install & setting
wget http://jpsysgit.qoo10jp.net/jpsysadmin/public_share/raw/master/filebeat/linux_filebeat/filebeat-7.6.1-x86_64.rpm
yum install -y ~/filebeat-7.6.1-x86_64.rpm
wget http://jpsysgit.qoo10jp.net/jpsysadmin/public_share/raw/master/filebeat/linux_filebeat/filebeat.yml -O /etc/filebeat/filebeat.yml
sed -i 's/Environment="BEAT_LOG_OPTS=-e"/#Environment="BEAT_LOG_OPTS=-e"/g' /usr/lib/systemd/system/filebeat.service
systemctl daemon-reload
systemctl enable filebeat.service
systemctl restart filebeat.service

## ad setting
yum install -y sssd realmd oddjob oddjob-mkhomedir samba-common-tools
echo 'ad password input'
realm join --user=administrator qoo10jp.inc 
sed -i 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf
sed -i 's/#auth\t\trequired\tpam_wheel/auth\t\trequired\tpam_wheel/g' /etc/pam.d/su
sed -i 's/wheel:x:10:/wheel:x:10:daesukim,yoin,mcon,hyeonshin/g' /etc/group
echo 'AllowUsers daesukim@172.30.12.41 yoin@172.30.12.43 mcon@172.30.12.42 hyeonshin@172.30.12.40' >> /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
chown root:wheel /usr/bin/sudo
chmod 4110 /usr/bin/sudo
systemctl restart sssd.service
systemctl restart sshd.service

## commit & reboot
sync
reboot
