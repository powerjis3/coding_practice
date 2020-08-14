#!/usr/bin/env bash

while read ip
do
  echo $ip | tee -a result.txt
  ping $ip -t 2 |  tee -a result.txt
done < dev_ip_list
