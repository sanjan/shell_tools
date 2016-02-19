# Title: Update Socket Mover Client Configuration
# Description: Update sock_mv configuration and restart the updated processes in all Java MT Routers
# Instruction: Script can be executed by passing the last octet of the updated connection server ips (in decimal format) as argument
# Example Execution: update_sock_mv.sh 208 35 211
# Author: Sanjan Grero
# (c) Copyright 2011 SAP Inc.

#!/bin/sh
SSH2="/usr/bin/ssh -2"
SCP2="scp -p"

HOSTS=( 18 19 22 23 42 43 69 109 224 229 230 231 233 250 )

# Read file list
echo -n "Enter Server IP List (ex: 208 211 35):"
#FILELIST=("$@")
read FILELIST
if [ "${FILELIST[0]}" == "" ]; then
echo "Argument list is empty!" 
echo "Exiting..."
exit 1
fi

#Check if files exist
echo "Scanning for sock_mv configuration files for provided IP list..."
for FILE in ${FILELIST[@]}
do
echo "Looking for /opt/mobileway/etc/sock_mv-$FILE.ini"
	if [ -f /opt/mobileway/etc/sock_mv-$FILE.ini ]; then
    echo "OK: The file sock_mv-$FILE.ini exist."
	else
	echo "ERROR: The file sock_mv-$FILE.ini do not exist."
	echo "Unable to proceed. Exiting..."
	exit 2
	fi
done

echo "Copying changed sock_mv configuration files to all routers"

for FILE in ${FILELIST[@]}
do
    for I in ${HOSTS[@]}
    do
    echo "Copying file sock_mv-$FILE.ini to 192.168.60.$I ..."
    $SCP2 /opt/mobileway/etc/sock_mv-$FILE.ini production1@192.168.60.$I:/opt/mobileway/etc
    done
done

echo ""
echo "Restarting updated sock_mv process in all routers"

for FILE in ${FILELIST[@]}
do
    for I in ${HOSTS[@]}
    do
        echo "Looking for process sock_mv-$FILE in 192.168.60.$I ..."
        $SSH2 192.168.60.$I "/opt/mobileway/bin/lc status | grep ^sock_mv | while read process pid; do if [ \$process == sock_mv-$FILE ]; then echo \"Restarting process: \$pid - \$process\"; kill -1 \$pid ;sleep 1;fi;done"
        echo ""
    done
done


echo "Count down 10 seconds for all processes to reload cleanly !"
sleep 10


echo ""
echo "Restart any \"lc nok\" process(es) on JMT Router Servers ..."
sleep 1

for I in ${HOSTS[@]}
do
        echo "Processing 192.168.60.$I ... Restarting"
        $SSH2 192.168.60.$I "/opt/mobileway/bin/lc reconf"
        echo ""
done

exit 0
