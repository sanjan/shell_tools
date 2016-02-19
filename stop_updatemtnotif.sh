#!/bin/bash
ALLHOSTS=( 001 002 003 004 005 006 007 008 009 010 101 102 103 104 )

echo stopping updatemtnotif processes
for i in ${ALLHOSTS[@]}
do
echo '************************'
echo fr1notif$i
ssh production1@fr1notif$i for i in \`/opt/HUB/lance/lc status \| grep ^updatemt \| awk \'{print \$1}\'\`\;do /opt/HUB/lance/lc stop \$i\;done
done

sleep 10
echo
echo checking stopped updatemtnotif processes
for i in ${ALLHOSTS[@]}
do
echo '************************'
echo fr1notif$i
ssh production1@fr1notif$i echo -n updatemtnotif processes stopped: \; /opt/HUB/lance/lc nok  \| grep ^updatemt \| wc -l
done
