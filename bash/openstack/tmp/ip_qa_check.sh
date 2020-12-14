#!/usr/bin/env bash

while read ip
do
  ping $ip -t 2 |  tee -a result_qa.txt
done < qa_ip_list
