#!/bin/bash
total_vcpu=0;total_alloc_vcpu=0;total_usage_vcpu=0;total_mem=0;total_usage_mem=0
cpu_alloc_ratio=1
mem_reserved_mb=4096

source ~/admin-openrc
openstack hypervisor list -c "Hypervisor Hostname" -f value > /root/wmp/script/imsy.txt
while read line
do
        resource_usage=($(openstack host show $line -c "CPU" -c "Memory MB" -f value))

        total_alloc_vcpu=`expr ${resource_usage[0]} \* $cpu_alloc_ratio`
        total_available_mem=`expr ${resource_usage[1]} - $mem_reserved_mb`

        echo "used resource of "$line " : " ${resource_usage[4]} "/" $total_alloc_vcpu "vcore  && " ${resource_usage[5]} "/" $total_available_mem "MB"

        total_usage_vcpu=`expr $total_usage_vcpu + ${resource_usage[4]}`
        total_vcpu=`expr $total_vcpu + $total_alloc_vcpu`

        total_usage_mem=`expr $total_usage_mem + ${resource_usage[5]}`
        total_mem=`expr $total_mem + $total_available_mem`

done < /root/wmp/script/imsy.txt

echo
echo "total used vcpu = " $total_usage_vcpu "/" $total_vcpu "vcore"
echo "total used memory = " $total_usage_mem "/" $total_mem "MB"
