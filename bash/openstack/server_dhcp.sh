#!/bin/bash
zone_info=a_zone
home="~/script"

#### env info ####
#project=new
#project=old
project=admin
source ~/$project-openrc

## az info
#az_info=nova
#az_info=a_zone-nova01
az_info=a_zone-highspec

## network info
net_info=192_168_56/24
#net_info=192_168_57/24

## image info
#vm_image=Ubuntu16-Template-v1.1
#vm_image=Ubuntu16-Template-v1.2
vm_image=Ubuntu16-Template-v1.3

## user data
#user_data=~/user_data/ubuntu_user_data.sh
#user_data=~/user_data/test1_user_data.sh
#user_data=~/user_data/test2_user_data.sh


#### openstack ####
## port info file
function ip_uuid_info() {
  openstack port list -f value > $home/portlist.txt
  echo "## port info update ##"
  return;
}

## port info
function ip_confirm() {
  dst_ip_uuid=`cat $2 |grep -i "$1 " |awk '{print $1}'`
  return;
}


ip_uuid_info
while read dst_hostname dst_flavor dst_ip
do

ip_confirm $dst_ip $home/portlist.txt

if [ -z $dst_ip_uuid  ];
  then
    source ~/admin-openrc
    openstack port create --network service-net-$net_info --fixed-ip subnet=service-subnet-$net_info,ip-address=$dst_ip --project $project $dst_ip
    ip_uuid_info; ip_confirm $dst_ip $home/portlist.txt
fi

## server
sourceo~/$project-openrc

openstack server create \
--image $vm_image \
--flavor $dst_flavor \
--nic port-id=$dst_ip_uuid \
--availability-zone $az_info \
$dst_hostname

#--user-data $user_data \
#--availability-zone $az_info \
#--availability-zone $az_info:$host_node \

done < list.txt

## list.txt info
# hostname  flavor  IP
# ex)
# hostname01c.example.nd    4vcpu_8mem_50G  192.168.56.11

