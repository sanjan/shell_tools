#!/bin/sh

CONF=$1


if [ -f $CONF ]
        then echo use ${CONF} as configuration file
else
        echo ${CONF} no found
        exit -1
fi

while true
do
        for i in `cut -d, -f2 ${CONF} | sort | uniq`
        do
                echo
                find $i/ -type f | xargs rm -f
        done
        find /opt/HUB/NOTIF/updatemtnotif/error/database/archive  -type f | xargs rm -f
	find /opt/HUB/NOTIF/updatemtnotif/warning  -type f | xargs rm -f
        sleep 70
done
