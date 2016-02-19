#!/bin/bash

SSH2="/usr/bin/ssh -2"

sqlquery=/var/home/sgrero/sqlscripts/deactive_ixng_cust.sql
sqlresult=/var/home/sgrero/temp/queryresult.txt
sqlresulttemp=/var/home/sgrero/temp/queryresulttemp.txt
emailbody=/var/home/sgrero/temp/emailbody.html
smppresult=/var/home/sgrero/temp/smppresult

DATE=`date '+%Y-%m-%d'`
DATE2=`date '+%Y%m%d%H%M'`
HOSTS=( 95 96 110 )
#for i in `find /opt/HUB/swiftmq/config/smppsvr_*/ -name "routerconfig.xml" 2>/dev/null`; do cat $i | awk 'BEGIN{FS="<!--";RS="-->"}/</{print $2}' >> ./result.text; done; cat ./result.text | awk 'BEGIN{FS="swift-queue-tx=\"";RS="_MO"}/</{print $2}'

echo "Running SQL query ..."
/opt/oracle/OraHome1/bin/sqlplus -s sgrero@billing/sgrero1312# @$sqlquery > $sqlresulttemp
echo "Querying complete."
cat $sqlresulttemp | grep -v -- "--" | grep -v "CUSTOMERID" | grep -v "row" | grep -v '^$' | sort -n  > $sqlresult
echo "<html>" >$emailbody
echo "<title>CLOSED IXNG CUSTOMER LIST - $DATE</title>" >>$emailbody
echo "<body><font face=\"verdana\" size=\"3\">" >>$emailbody
echo "" > $smppresult\_commented.txt
echo "" > $smppresult\_active.txt

for I in ${HOSTS[@]}
        do
        echo "Extracting data from 192.168.60.$I ..."
        $SSH2 192.168.60.$I for i in \`find /opt/HUB/swiftmq/config/smppsvr\_*/ -name routerconfig.xml\`\; do  echo \"\$i\" > $smppresult\_$I\_files.txt \; done\;

        for line in `cat  $smppresult\_$I\_files.txt`
        do
        portname=`echo "$line" | cut -d\_ -f2 | cut -d/ -f1`
        $SSH2 192.168.60.$I cat $line > $smppresult\_$I\_$portname.txt
        cat $smppresult\_$I\_$portname.txt | sed  '/<!--/,/-->/d' | awk 'BEGIN{FS="swift-queue-tx=\"";RS="_MO"}/</{print $2}'| sed -e 's/^[ \t]*//' | sed '/^$/d' | sort -n | uniq > $smppresult\_$I\_$portname\_active.txt
        done


#       $SSH2 192.168.60.$I for i in \`find /opt/HUB/swiftmq/config/smppsvr\_\*/ -name routerconfig.xml\`\; do cat \$i > $smppresult$I.txt \; done\;
#       cat $smppresult$I.txt | awk 'BEGIN{FS="<!--";RS="-->"}/</{print $2}' | awk 'BEGIN{FS="swift-queue-tx=\"";RS="_MO"}/</{print $2}'| sed -e 's/^[ \t]*//' | sed '/^$/d' | sort -n | uniq >  $smppresult\_commented\_$I.txt
#       cat $smppresult\_commented\_$I.txt >> $smppresult\_commented.txt
#       echo "Below customer accounts already commented in 192.168.60.$I"
#       grep -f $sqlresult $smppresult\_commented\_$I.txt
#       echo ""

        #removing commented lines from grabbed xml file
#       cat $smppresult$I.txt | sed  '/<!--/,/-->/d' | awk 'BEGIN{FS="swift-queue-tx=\"";RS="_MO"}/</{print $2}'| sed -e 's/^[ \t]*//' | sed '/^$/d' | sort -n | uniq > $smppresult\_active\_$I.txt
#       cat $smppresult\_active\_$I.txt >>  $smppresult\_active.txt
done
echo "Extracting data complete."
echo ""
echo "Generating email content ..."
echo "<h4>Below suspended/closed customer accounts are still ACTIVE in smppinput servers as of $DATE</h4>" >> $emailbody
echo "<p>Customer Account - Server IP - Port - Status - Update Date</p>" >> $emailbody
counter=0
for I in ${HOSTS[@]}
do
counterd=0

for filename in  $smppresult\_$I\_*\_active.txt
do
portnum=`echo "$filename" | cut -d\_ -f3`
echo "checking $portnum in 192.168.60.$I ..."
while read linesql
do
linesqcust=`echo $linesql | awk '{ print $1 }'`
linesqsusp=`echo $linesql | awk '{ print $2 }'`
linesqclos=`echo $linesql | awk '{ print $3 }'`

        while read linefile
        do
        if [ "$linesqcust" == "$linefile" ]; then

        counter=$(( $counter + 1 ))
        counterd=$(( $counterd + 1 ))

                if [ "$linesqsusp" != "NULL" ]; then
                echo "<p>$linesqcust - 192.168.60.$I - $portnum  - Suspended - $linesqsusp</p>" >>$emailbody
                else
                echo "<p>$linesqcust - 192.168.60.$I - $portnum - Closed - $linesqclos</p>" >>$emailbody
                fi
        fi
        done < $filename
done < $sqlresult

done

done
echo ""
echo "<p>in total $counter accounts need to be commented.</p>"  >>$emailbody
echo "</font></body></html>" >>$emailbody
echo "Generating email content complete."
echo "Sending email ..."
/var/home/sgrero/shellscripts/sendhtmlmail.sh sgrero@sybase.com $emailbody "Inactive IXNG Customer Accounts - $DATE"
echo "email sent."
