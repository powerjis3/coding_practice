#!/usr/bin/python3
import json
import ipaddress
import os, sys

def get_json():

    json_file = "/tmp/subnet_list.json"
    json_data = open(json_file).read()

    data = json.loads(json_data)

    return data

def get_vlan(data, ip_addr):

    for (k, v) in data.items():
       addr_v4 = ipaddress.ip_address(ip_addr)
       try:
           if addr_v4 in ipaddress.ip_network(k):
               check_val = True
               return (v)
               break;
           else:
               check_val = False
       except ValueError:
           pass

    if check_val is False:
        print("vlan is mssing.")
        sys.exit()

def get_netinfo(os_type):

    if os_type == "Ubuntu":

        ip_addr_get = os.popen("grep -i address /etc/network/interfaces | awk '{print$2}'")
        netmask_get = os.popen("grep -i netmask /etc/network/interfaces | awk '{print$2}' | sed -n 1p")
        gateway_get = os.popen("grep -i gateway /etc/network/interfaces | awk '{print$NF}'")

    else:

        ip_addr_get = os.popen("grep -i IPADDR /etc/sysconfig/network-scripts/ifcfg-eth0  | awk -F= '{print$2}'")
        netmask_get = os.popen("grep -i NETMASK /etc/sysconfig/network-scripts/ifcfg-eth0 | awk -F= '{print$2}'")
        gateway_get = os.popen("grep -i GATEWAY /etc/sysconfig/network | awk -F= '{print$2}'")

    ip_addr = ip_addr_get.read().strip()
    netmask = netmask_get.read().strip()
    gateway = gateway_get.read().strip()

    return ip_addr, netmask, gateway

def set_bond(os_type, vlan_id, ip_addr, netmask, gateway):

    if os_type == "Ubuntu":

        text = "# This file describes the network interfaces available on your system\n# and how to activate them. For more information, see interfaces(5).\n\nsource /etc/network/interfaces.d/*\
        \n\n# The loopback network interface\nauto lo\niface lo inet loopback\n\n# The primary network interface\nauto eno1\niface eno1 inet manual\nbond-master bond0\n\nauto eno2\n\
iface eno2 inet manual\nbond-master bond0\n\nauto bond0\niface bond0 inet manual\nbond-mode 4\nbond-lacp-rate 1\nbond-miimon 100\nbond-xmit_hash_policy layer3+4\nbond-slaves none\n\n\
auto bond0." + vlan_id + "\niface bond0." + vlan_id + " inet static\naddress " + ip_addr + "\nnetmask " + netmask + "\ngateway " + gateway + "\nvlan-raw-device bond0"

        f = open("/etc/network/interfaces", "w")
        f.write(text)
        f.close()

    else:

        text = [ "DEVICE=eth0\nONBOOT=yes\nTYPE=Ethernet\nBOOTPROTO=none\nSLAVE=yes\nMASTER=bond0", "DEVICE=eth1\nONBOOT=yes\nTYPE=Ethernet\nBOOTPROTO=none\nSLAVE=yes\nMASTER=bond0",\
        "DEVICE=bond0\nONBOOT=yes\nTYPE=Ethernet\nBOOTPROTO=none\nBONDING_MASTER=yes\nBONDING_OPTS=" + '"' + "mode=4 miimon=100 xmit_hash_policy=layer3+4" + '"',\
        "DEVICE=bond0." + vlan_id + "\nONBOOT=yes\nTYPE=Ethernet\nBOOTPROTO=none\nIPADDR=" + ip_addr + "\nNETMASK=" + netmask + "\nGATEWAY=" + gateway + "\nUSERCTL=no\nVLAN=yes"]

        eth_path = [ "/etc/sysconfig/network-scripts/ifcfg-eth0", "/etc/sysconfig/network-scripts/ifcfg-eth1", "/etc/sysconfig/network-scripts/ifcfg-bond0", "/etc/sysconfig/network-scripts/ifcfg-bond0." + vlan_id ]

        for i in enumerate(eth_path):
            f = open(i[1], "w")
            f.write(text[i[0]])
        f.close()

    return False

def os_type_get():

    os_type = os.popen("cat /etc/issue | awk '{print$1}' | sed -n 1p").read().strip()

    return os_type

if __name__ == '__main__':

    os_type = os_type_get()
    get_json_data = get_json()
    vlan_id = get_vlan(get_json_data, get_netinfo(os_type)[0])
    ip_address = get_netinfo(os_type)[0]
    set_bond(os_type, vlan_id, get_netinfo(os_type)[0], get_netinfo(os_type)[1], get_netinfo(os_type)[2])
