#!/bin/bash

echo "MT Router Batch Script"
echo "======================"
echo
date

#MAINHOSTS=( fr1mtrouter001 fr1mtrouter002 fr1mtrouter003 fr1mtrouter004 fr1mtrouter005 fr1mtrouter006 fr1mtrouter007 fr1mtrouter008 fr1mtrouter009 fr1mtrouter010 fr1mtrouter011 fr1mtrouter012 fr1mtrouter013 fr1mtrouter014 fr1mtrouter101 fr1mtrouter102 uk4mtrouter01 uk4mtrouter02 uk4mtrouter003 uk4mtrouter004 uk4mtrouter005 uk4mtrouter006 )
MAINHOSTS=( fr1mtrouter001 fr1mtrouter002 fr1mtrouter003 fr1mtrouter004 fr1mtrouter005 fr1mtrouter006 fr1mtrouter007 fr1mtrouter008 fr1mtrouter009 fr1mtrouter010 fr1mtrouter011 fr1mtrouter012 fr1mtrouter013 fr1mtrouter014 fr1mtrouter101 fr1mtrouter102 )
read -r -p "Enter command: " command
echo ${command}
for host in ${MAINHOSTS[@]}
do
echo -e "\n${host} : "
#ssh production1@${i} ${command}
ssh -T production1@$host /bin/bash <<EOF

export PATH=\$PATH:/opt/HUB/bin

${command}

EOF

done
date
