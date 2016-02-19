#!/bin/bash

echo "MO Router Batch Script"
echo "======================"
echo
date

MAINHOSTS=( fr1morouter001 fr1morouter002 fr1morouter101 fr1morouter102 uk4morouter01 uk4morouter02 )
read -r -p "Enter command: " command
echo ${command}
for i in ${MAINHOSTS[@]}
do
echo -e "\n${i} : "
ssh production1@${i} ${command}
done
date
