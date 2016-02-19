 find /opt/HUB/swiftmq/config/smppsvr_*/ -name routerconfig.xml 2>/dev/null
 
 select customerid from customers where liveaccount=0 and customerid in ( select customerid from customers where  updatemtnotif_out like  '%ng_smpp' or updatemtnotif_out like '%smpp_12000' or updatemtnotif_out like '%smpp_7906' or updatemtnotif_out like '%smpp_7911' or updatemtnotif_out like '%smpp_7913' or updatemtnotif_out like '%smpp_7915' or updatemtnotif_out like '%smpp_7916' or updatemtnotif_out like '%smpp_7919' or updatemtnotif_out like '%ng_smpp_tss') and closuredate < (SYSDATE-7) order by closuredate desc;
 
 select customerid,liveaccount,suspenddate,closuredate from customers where liveaccount=0 and customerid in ( select customerid from customers where  updatemtnotif_out like  '%ng_smpp' or updatemtnotif_out like '%smpp_12000' or updatemtnotif_out like '%smpp_7906' or updatemtnotif_out like '%smpp_7911' or updatemtnotif_out like '%smpp_7913' or updatemtnotif_out like '%smpp_7915' or updatemtnotif_out like '%smpp_7916' or updatemtnotif_out like '%smpp_7919' or updatemtnotif_out like '%ng_smpp_tss') and closuredate < (SYSDATE-7) or suspenddate < (SYSDATE-7) order by customerid;
 
 [cng@fr1output2:~] > cat /var/home/cng/script/check_deliveryrate.sh
#!/bin/bash
QUERY=/var/home/cng/script/check_deliveryrate.sql
RESULT=/var/home/cng/script/check_deliveryrate.result
FINALREPORT=/var/home/cng/script/message.txt
emailbody=/var/home/cng/script/emailbody.txt
tmpfile=/tmp/check_deliveryrate.tmp

/opt/oracle/OraHome1/bin/sqlplus cng/CLIVE1  @$QUERY  > $RESULT

grep -A5 SMSCID $RESULT > $tmpfile ;grep -v Disconnected $tmpfile > $FINALREPORT

echo "<html>" >>$emailbody
echo "<title>DELIVERYRATE CONFIGURATION</title>" >>$emailbody
echo "<body>" >>$emailbody
echo "<h4>Current SMSCID with Delivery rate set</h4>" >>$emailbody

while read line
do

        echo "<p> $line </p>" >> $emailbody
done <  $FINALREPORT

echo "</body></html>" >>$emailbody

/var/home/cng/script/sendhtmlmail.sh clive.ng@sybase.com $emailbody "DELIVERYRATE"

rm $emailbody
rm $FINALREPORT
rm $tmpfile

echo `date`
echo "COMPLETED"

==================================================================================================================================

#!/bin/bash

SSH2="/usr/bin/ssh -2"

sqlquery=/var/home/sgrero/scripts/deactive_ixng_cust.sql
sqlresult=/var/home/sgrero/temp/queryresult.txt
sqlresulttemp=/var/home/sgrero/temp/queryresulttemp.txt
emailbody=/var/home/sgrero/temp/emailbody.html
smppresult=/var/home/sgrero/temp/smppresult

DATE=`date '+%Y-%m-%d'`
DATE2=`date '+%Y%m%d%H%M'`
HOSTS=( 95 96 110 )
#for i in `find /opt/HUB/swiftmq/config/smppsvr_*/ -name "routerconfig.xml" 2>/dev/null`; do cat $i | awk 'BEGIN{FS="<!--";RS="-->"}/</{print $2}' >> ./result.text; done; cat ./result.text | awk 'BEGIN{FS="swift-queue-tx=\"";RS="_MO"}/</{print $2}'

echo "Running SQL query ..."
xx=`/opt/oracle/OraHome1/bin/sqlplus -s sgrero@billing/sgrero1312# @$sqlquery > $sqlresulttemp`
echo "Querying complete."
cat $sqlresulttemp | grep -v -- "--" | grep -v "CUSTOMERID" | grep -v "row" | grep -v '^$' | sed -e 's/^[ \t]*//' | sed '/^$/d' | sort -n  > $sqlresult

echo "<html>" >>$emailbody
echo "<title>CLOSED IXNG CUSTOMER LIST - $DATE</title>" >>$emailbody
echo "<body>" >>$emailbody
echo "<h4>Closed Suspended IXNG Customer ID List - $DATE<h4>" >> $emailbody

while read line
do
        echo "<p> $line </p>" >> $emailbody
done <  $sqlresult

echo "</body></html>" >>$emailbody
echo "Generating email body complete."
echo ""
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
echo "Below suspended/closed customer accounts are still ACTIVE in smppinput servers"
echo ""
counter=0
for I in ${HOSTS[@]}
do
echo "Need to be commented in 192.168.60.$I"
echo "====================================="
echo ""
counterd=0
for filename in  $smppresult\_$I\_*\_active.txt
        do
portnum=`echo "$filename" | cut -d\_ -f3`
   #     echo "port: smppsvr_$portnum"
   #     echo "======================"
#       echo ""
while read linesql
do
        while read linefile
        do
        if [ "$linesql" == "$linefile" ]; then
        counter=$(( $counter + 1 ))
        counterd=$(( $counterd + 1 ))
        echo "$linefile - $portnum"
        fi
        done < $filename
done < $sqlresult
echo ""
done
echo ""
echo "$counterd accounts found in  192.168.60.$I"
echo ""
done
echo "in total $counter accounts need to be commented."
