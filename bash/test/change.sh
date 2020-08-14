#!/bin/bash

while read line1 line2
do
sed  "s/$line1/$line1 $line2/g" source > result
mv result source
done < data
