#!/bin/bash

if [ $# -lt 4 ];then
    echo "## value - add/del iplist_file ssh/group/all id ip ##"
    echo -e "\nUsage1 : $0 add/del iplist_file group id"
    echo "Usage2 : $0 add/del iplist_file ssh/all id ip"
    echo -e "\n  ex) $0 del iplist.txt group harry"
    echo -e "      $0 add iplist.txt all harry 192.168.56.11"
    exit 1
else
    if [ ! -f $2 ];then
        echo "File  $2 does not exist!"
        exit 0
    else
        echo 'test'
    fi
fi

#echo -n 'input ad user_id : '
#read USER_ID
#
#echo -n 'input password : '
#stty -echo
#read PASSWORD
#stty echo
#echo ' '
USER_ID='test'
PASSWORD='test123'

### initialize result file ###
cat /dev/null > result.txt


### add main ###
while read IP
do

## OS check ##
OS_ISSUE=$(sshpass -p $PASSWORD ssh -o ConnectTimeout=2 $USER_ID@$IP  -no StrictHostKeyChecking=no "cat /etc/issue | awk '{print \$1}' | sed -n 1p | tr '[A-Z]' '[a-z]'")
OS_VERSION=$(sshpass -p $PASSWORD ssh -o ConnectTimeout=2 $USER_ID@$IP  -no StrictHostKeyChecking=no "cat /etc/redhat-release | sed 's/[a-z,A-Z]//g' | awk '{print \$1}'")

## ssh_allow add ##
SSH_ALLOW_ADD=$(sshpass -p $PASSWORD ssh -o ConnectTimeout=2 $USER_ID@$IP  -no StrictHostKeyChecking=no "echo $PASSWORD | sudo -S sed -ie '/^AllowUsers/ s/$/ $4@$5/' /root/tmp/sshd_config")
CENTOS_GROUP_ADD=$(sshpass -p $PASSWORD ssh $USER_ID@$IP  -no StrictHostKeyChecking=no  "echo $PASSWORD | sudo -S sed -ie '/^wheel:/ s/$/,$4/' /root/tmp/group")
UBUNTU_GROUP_ADD=$(sshpass -p $PASSWORD ssh $USER_ID@$IP  -no StrictHostKeyChecking=no  "echo $PASSWORD | sudo -S sed -ie '/^sudo:/ s/$/,$4/' /root/tmp/group")
SSH_RESTART_SYSTEMD=$(sshpass -p $PASSWORD ssh $USER_ID@$IP  -no StrictHostKeyChecking=no  "echo $PASSWORD | sudo -S systemctl restart sshd")
SSH_RESTART_INITD=$(sshpass -p $PASSWORD ssh $USER_ID@$IP  -no StrictHostKeyChecking=no  "echo $PASSWORD | sudo -S /etc/init.d/sshd restart")

echo -n "$IP" | tee -a result.txt

if [ -z $OS_ISSUE ];then
    echo '' >> result.txt
    continue
elif [ $OS_ISSUE == ubuntu ];then
    echo ' - connect ubuntu server' | tee -a result.txt
    $SSH_ALLOW_ADD
    $UBUNTU_GROUP_ADD
    $SSH_RESTART_SYSTEMD
else
    echo -n ' - connect centos server' | tee -a result.txt
    $SSH_ALLOW_ADD
    $CENTOS_GROUP_ADD
    if [ ${OS_VERSION:0:1} -eq 6 ];then
        $SSH_RESTART_INITD
    else
        $SSH_RESTART_SYSTEMD
    fi
fi

done < $2

cat result.txt | grep -v -E ^$ >> result.tmp
mv result.tmp result.txt
