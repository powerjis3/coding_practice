#!/bin/bash

cat /dev/null > result.txt

while read line
do
if [ -z ${line} ]
then
	echo -e | tee -a result.txt
continue;
fi
cat tt | grep $line | tee -a result.txt
data=$(cat tt | grep ${line})
if [ -z ${data} ]
then
	echo -e | tee -a result.txt
continue;
fi
done < source
