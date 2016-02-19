#!/bin/bash

source /opt/HUB/report/scripts/mobileway.sh
source /opt/HUB/sybase/ASE-SDK-15.7/SYBASE.sh

dateexe=/usr/local/bin/date

TODAY=`date`
LOG="/opt/HUB/reportserver/staging/log/deploy_report_stag.log"
SQL_PATH="/opt/HUB/reportserver/deploy/"

echo "Please enter the SQL Filename (Staging):"

read IN_SQL_FILE

if [ -z $IN_SQL_FILE ]
then
        echo "Invalid Filename. Please try again."
else
        echo "Deploying SQL filename $IN_SQL_FILE in Staging .... "
        echo "$TODAY : Deploying SQL filename $IN_SQL_FILE in Staging .... " >> $LOG
        SQL_ACT=$SQL_PATH$IN_SQL_FILE
        echo $SQL_ACT
fi

/opt/HUB/sybase/ASE-SDK-15.7/OCS-15_0/bin/isql -Ureport_user -PG0r8psvr -STIQA2P4_1 -i $SQL_ACT -o /tmp/deploy_report_stag.out -w 1024

cat /tmp/deploy_report_stag.out >> $LOG

echo "Deployment completed done in Staging. Please check the report..."

END_DATE=`date`

echo "$END_DATE : Deployment completed done in staging. Please check the report..." >> $LOG

rm -f /tmp/deploy_report_stag.out
