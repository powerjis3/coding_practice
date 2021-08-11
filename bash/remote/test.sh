#!/bin/bash

############    function  ##################

GUIDE() {
    cat << guide_cat

    ## value - add/del iplist_file ssh/group/all id ip ##

    Usage1 : $0 add/del iplist_file group id
    Usage2 : $0 add/del iplist_file ssh/all id ip

    ex) $0 del iplsit.txt group harry
        $0 add iplist.txt all harry 192.168.56.11

guide_cat
    exit 1
}

FORMAT_CHECK() {
if [ $# -lt 4 ];then
    GUIDE
else
    ## add/del chech ##
    if [ $1 != add ]&&[ $1 != del ];then
        echo " ## In the first field, input one of the two \"add/del\" ##"
        exit 0
    ## iplist file check ##
    elif [ ! -f $2 ];then
        echo "## File $2 does not exist! ##"
        exit 0
    ## target check ##
    elif [ $3 != ssh ]&&[ $3 != group ]&&[ $3 != all ];then
        echo "## In the third field, input one of the three \"ssh/group/all\" ##"
        exit 0
    ## check the ip to be added ##
    elif [ $3 = ssh ]||[ $3 = all ];then
        if [ -z "$5" ];then
            echo "    ## input the 5th variable ##"
            GUIDE
        else
            ## ipv4 format check ##
            DECIMAL=($(echo $5 | sed 's/\./ /g'))
            if [ ${#DECIMAL[@]} -eq 4 ];then
                for NUM in ${DECIMAL[@]}
                do
                    if ! [[ $NUM =~ ^[0-9]*$ ]]||[ $NUM -lt 0 ]||[ $NUM -gt 255 ];then
                        echo "## Input the IP address that matches the format (xx.xx.xx.xx) ##"
                        echo "ex) 192.168.56.11"
                        exit 0
                    fi
                done
            else
                echo "## Input the IP address that matches the format (xx.xx.xx.xx) ##"
                echo "ex) 192.168.56.11"
                exit 0
            fi
            ## check complete ##
            cat << input_value
job         - $1
iplist file - $2
target      - $3
user id     - $4
user ip     - $5

input_value
        fi
    else
        if [ -n "$5" ];then
            echo "## delete the 5th value ##"
            exit 0
        fi
        cat << input_value
job         - $1
iplist file - $2
target      - $3
user id     - $4

input_value
    fi
fi
}

LOGIN() {
echo -n 'input ad user_id : '
read USER_ID

echo -n 'input password : '
stty -echo
read PASSWORD
stty echo
echo -e "\n"
}

ADD_PROCESS() {
while read IP
do

## OS check ##
OS_ISSUE=$(sshpass -p $PASSWORD ssh -o ConnectTimeout=2 $USER_ID@$IP  -no StrictHostKeyChecking=no "cat /etc/issue | awk '{print \$1}' | sed -n 1p | tr '[A-Z]' '[a-z]'" 2>/dev/null)
OS_VERSION=$(sshpass -p $PASSWORD ssh -o ConnectTimeout=2 $USER_ID@$IP  -no StrictHostKeyChecking=no "cat /etc/redhat-release | sed 's/[a-z,A-Z]//g' | awk '{print \$1}'" 2>/dev/null)

## user check
SSH_ALLOW_CHECK=$(sshpass -p $PASSWORD ssh -o ConnectTimeout=2 $USER_ID@$IP  -no StrictHostKeyChecking=no "echo $PASSWORD | sudo -S cat /root/tmp/sshd_config | grep AllowUsers | grep $4@$5 | wc -l" 2>/dev/null)
CENTOS_GROUP_CHECK="sshpass -p $PASSWORD ssh $USER_ID@$IP  -no StrictHostKeyChecking=no  echo $PASSWORD | sudo -S cat /root/tmp/group | grep wheel | grep $4 | wc -l"
UBUNTU_GROUP_CHECK="sshpass -p $PASSWORD ssh $USER_ID@$IP  -no StrictHostKeyChecking=no  echo $PASSWORD | sudo -S cat /root/tmp/group | grep sudo | grep $4 | wc -l"

## user add ##
SSH_ALLOW_ADD="sshpass -p $PASSWORD ssh $USER_ID@$IP  -no StrictHostKeyChecking=no echo $PASSWORD | sudo -S sed -ie '/^AllowUsers/ s/$/ $4@$5/' /root/tmp/sshd_config"
UBUNTU_GROUP_ADD="sshpass -p $PASSWORD ssh $USER_ID@$IP -no StrictHostKeyChecking=no echo $PASSWORD | sudo -S sed -ie '/^sudo:/ s/$/,$4/' /root/tmp/group && echo $PASSWORD | sudo -S sed -ie '/^sudo:/ s/:,/:/' /root/tmp/group"
CENTOS_GROUP_ADD="sshpass -p $PASSWORD ssh $USER_ID@$IP -no StrictHostKeyChecking=no echo $PASSWORD | sudo -S sed -ie '/^wheel:/ s/$/,$4/' /root/tmp/group && echo $PASSWORD | sudo -S sed -ie '/^wheel:/ s/:,/:/' /root/tmp/group"
SSH_RESTART_SYSTEMD="sshpass -p $PASSWORD ssh $USER_ID@$IP  -no StrictHostKeyChecking=no echo $PASSWORD | sudo -S systemctl restart sshd"
SSH_RESTART_INITD="sshpass -p $PASSWORD ssh $USER_ID@$IP  -no StrictHostKeyChecking=no echo $PASSWORD | sudo -S /etc/init.d/sshd restart"


echo -n "$IP" | tee -a result.txt

if [[ -z $OS_ISSUE ]];then
    echo ' - connect fail' | tee -a result.txt
    continue
elif [[ $OS_ISSUE = ubuntu ]];then
    echo -n ' - connect ubuntu server' | tee -a result.txt
    if [ $3 = group ];then
        if [[ $($UBUNTU_GROUP_CHECK) != 0 ]];then
            echo ' - The group_user value already exists - fail' | tee -a result.txt
            continue
        else
            echo " - add group_user" | tee -a result.txt
            $UBUNTU_GROUP_ADD 2>/dev/null
        fi
    elif [ $3 = ssh ];then
        if [ $SSH_ALLOW_CHECK != 0 ];then
            echo ' - The ssh_user value already exists - fail' | tee -a result.txt
            continue
        else
            echo -n " - add ssh_user" | tee -a result.txt
            $SSH_ALLOW_ADD 2>/dev/null
            echo " - restart sshd(systemd)" | tee -a result.txt
            $SSH_RESTART_SYSTEMD 2>/dev/null
        fi
    else
        if [ $SSH_ALLOW_CHECK != 0 ]||[[ $($UBUNTU_GROUP_CHECK) != 0 ]];then
            if [ $SSH_ALLOW_CHECK != 0 ]&&[[ $($UBUNTU_GROUP_CHECK) != 0 ]];then
                echo ' - The ssh/group_user value already exists - fail' | tee -a result.txt
                continue
            elif [ $SSH_ALLOW_CHECK != 0 ];then
                echo ' - The ssh_user value already exists - fail' | tee -a result.txt
                continue
            else
                echo ' - The group_user value already exists - fail' | tee -a result.txt
                continue
            fi
        else
        echo -n " - add ssh/group_user" | tee -a result.txt
        $SSH_ALLOW_ADD 2>/dev/null
        $UBUNTU_GROUP_ADD 2>/dev/null
        echo " - restart sshd(systemd)" | tee -a result.txt
        $SSH_RESTART_SYSTEMD 2>/dev/null
        fi
    fi
else
    echo -n " - connect centos server" | tee -a result.txt
    if [ $3 = group ];then
        if [[ $($CENTOS_GROUP_CHECK) != 0 ]];then
            echo ' - The group_user value already exists - fail' | tee -a result.txt
            continue
        else
            echo ' - add group_user' | tee -a result.txt
            $CENTOS_GROUP_ADD 2>/dev/null
        fi
    elif [ $3 = ssh ];then
        if [ $SSH_ALLOW_CHECK != 0 ];then
            echo ' - The ssh_user value already exists - fail' | tee -a result.txt
            continue
        else
            echo -n " - add ssh_user" | tee -a result.txt
            $SSH_ALLOW_ADD 2>/dev/null
            if [ ${OS_VERSION:0:1} -eq 6 ];then
                echo " - restart sshd(initd)" | tee -a result.txt
                $SSH_RESTART_INITD 2>/dev/null
            else
                echo " - restart sshd(systemd)" | tee -a result.txt
                $SSH_RESTART_SYSTEMD 2>/dev/null
            fi
        fi
    else
        if [ $SSH_ALLOW_CHECK != 0 ]||[[ $($CENTOS_GROUP_CHECK) != 0 ]];then
            if [ $SSH_ALLOW_CHECK != 0 ]&&[[ $($CENTOS_GROUP_CHECK) != 0 ]];then
                echo ' - The ssh/group_user value alrready exists - fail' | tee -a result.txt
                continue
            elif [ $SSH_ALLOW_CHECK != 0 ];then
                echo ' - The ssh_user value already exists - fail' | tee -a result.txt
                continue
            else
                echo ' - The group_user value already exists - fail' | tee -a result.txt
                continue
            fi
        else
            echo -n " - add ssh/group_user" | tee -a result.txt
            $SSH_ALLOW_ADD 2>/dev/null
            $CENTOS_GROUP_ADD 2>/dev/null
            if [ ${OS_VERSION:0:1} -eq 6 ];then
                echo " - restart sshd(initd)" | tee -a result.txt
                $SSH_RESTART_INITD 2>/dev/null
            else
                echo " - restart sshd(systemd)" | tee -a result.txt
                $SSH_RESTART_SYSTEMD 2>/dev/null
            fi
        fi
    fi
fi

done < $2
}

DELETE_PROCESS() {
while read IP
do

## OS check ##
OS_ISSUE=$(sshpass -p $PASSWORD ssh -o ConnectTimeout=2 $USER_ID@$IP  -no StrictHostKeyChecking=no "cat /etc/issue | awk '{print \$1}' | sed -n 1p | tr '[A-Z]' '[a-z]'" 2>/dev/null)
OS_VERSION=$(sshpass -p $PASSWORD ssh -o ConnectTimeout=2 $USER_ID@$IP  -no StrictHostKeyChecking=no "cat /etc/redhat-release | sed 's/[a-z,A-Z]//g' | awk '{print \$1}'" 2>/dev/null)

## delete value ##
SSH_ALLOW_DEL="sshpass -p $PASSWORD ssh $USER_ID@$IP  -no StrictHostKeyChecking=no echo $PASSWORD | sudo -S sed -ie '/^AllowUsers/ s/ $4@$5//' /root/tmp/sshd_config"
UBUNTU_GROUP_DEL="sshpass -p $PASSWORD ssh $USER_ID@$IP -no StrictHostKeyChecking=no echo $PASSWORD | sudo -S sed -ie '/^sudo:/ s/,$4,\|,$4$/,/' /root/tmp/group && echo $PASSWORD | sudo -S sed -ie '/^sudo:/ s/,$//' /root/tmp/group && echo $PASSWORD | sudo -S sed -ie '/^sudo:/ s/:,\|:$4,\|:$4$/:/' /root/tmp/group"
CENTOS_GROUP_DEL="sshpass -p $PASSWORD ssh $USER_ID@$IP -no StrictHostKeyChecking=no echo $PASSWORD | sudo -S sed -ie '/^wheel:/ s/,$4,\|,$4$/,/' /root/tmp/group && echo $PASSWORD | sudo -S sed -ie '/^wheel:/ s/,$//' /root/tmp/group && echo $PASSWORD | sudo -S sed -ie '/^wheel:/ s/:,\|:$4,\|:$4$/:/' /root/tmp/group"
SSH_RESTART_SYSTEMD="sshpass -p $PASSWORD ssh $USER_ID@$IP  -no StrictHostKeyChecking=no echo $PASSWORD | sudo -S systemctl restart sshd"
SSH_RESTART_INITD="sshpass -p $PASSWORD ssh $USER_ID@$IP  -no StrictHostKeyChecking=no echo $PASSWORD | sudo -S /etc/init.d/sshd restart"


echo -n "$IP" | tee -a result.txt

if [[ -z $OS_ISSUE ]];then
    echo ' - connect fail' | tee -a result.txt
    continue
elif [[ $OS_ISSUE = ubuntu ]];then
    echo -n ' - connect ubuntu server' | tee -a result.txt
    if [ $3 = group ];then
        echo " - delete group_user" | tee -a result.txt
        $UBUNTU_GROUP_DEL 2>/dev/null
    elif [ $3 = ssh ];then
        echo -n " - delete ssh_user" | tee -a result.txt
        $SSH_ALLOW_DEL 2>/dev/null
        echo " - restart sshd(systemd)" | tee -a result.txt
        $SSH_RESTART_SYSTEMD 2>/dev/null
    else
        echo -n " - delete ssh/group_user" | tee -a result.txt
        $UBUNTU_GROUP_DEL 2>/dev/null
        $SSH_ALLOW_DEL 2>/dev/null
        echo " - restart sshd(systemd)" | tee -a result.txt
        $SSH_RESTART_SYSTEMD 2>/dev/null
    fi
else
    echo -n ' - connect centos server' | tee -a result.txt
    if [ $3 = group ];then
        echo " - delete group_user" | tee -a result.txt
        $CENTOS_GROUP_DEL 2>/dev/null
    elif [ $3 = ssh ];then
        echo -n " - delete ssh_user" | tee -a result.txt
        $SSH_ALLOW_DEL 2>/dev/null
        if [ ${OS_VERSION:0:1} -eq 6 ];then
            echo " - restart sshd(initd)" | tee -a result.txt
            $SSH_RESTART_INITD 2>/dev/null
        else
            echo " - restart sshd(systemd)" | tee -a result.txt
            $SSH_RESTART_SYSTEMD 2>/dev/null
        fi
    else
        echo -n " - delete ssh/group_user" | tee -a result.txt
        $CENTOS_GROUP_DEL 2>/dev/null
        $SSH_ALLOW_DEL 2>/dev/null
        if [ ${OS_VERSION:0:1} -eq 6 ];then
            echo " - restart sshd(initd)" | tee -a result.txt
            $SSH_RESTART_INITD 2>/dev/null
        else
            echo " - restart sshd(systemd)" | tee -a result.txt
            $SSH_RESTART_SYSTEMD 2>/dev/null
        fi
    fi
fi

done < $2
}


############    main  ##################

### script input format check
FORMAT_CHECK $1 $2 $3 $4 $5

### initialize result file ###
cat /dev/null > result.txt

### main ###
LOGIN
if [ $1 = add ];then
    ADD_PROCESS $1 $2 $3 $4 $5 
else
    DELETE_PROCESS $1 $2 $3 $4 $5
fi

### remove space ###
cat result.txt | grep -v -E ^$ >> result.tmp
mv result.tmp result.txt
