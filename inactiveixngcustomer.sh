# sanjan grero - 2011-01
#!/bin/bash

#line needed in order to execute under cron
export ORACLE_HOME=/opt/oracle/OraHome1

SSH2="/usr/bin/ssh -2"

sqlquery=/opt/mobileway/scripts/inactiveixngcust.sql
sqlresult=/tmp/inactiveixngcustdbqueryresult.txt
sqlresulttemp=/tmp/inactiveixngcustqueryresulttemp.txt
emailbody=/tmp/inactiveixngcustemail.html
resultbodyact=/tmp/inactiveixngcustresultact.html
resultbodycom=/tmp/inactiveixngcustresultcom.html
smppresult=/tmp/inactiveixngcustsmppresult

echo -n "" > $resultbodyact
echo -n "" > $resultbodycom

DATE=`date '+%Y-%m-%d'`
HOSTS=( 95 96 110 101 103 )

echo -e "`date '+%Y-%m-%d %H:%M:%S'`\tExecuting DB query ..."
/opt/oracle/OraHome1/bin/sqlplus -s sgrero@billing/sgrero1312# @$sqlquery |  grep -v '^$' | sed -e 's/^[ \t]*//' | sort -n > $sqlresult
echo -e "`date '+%Y-%m-%d %H:%M:%S'`\tDB Querying complete."


for I in ${HOSTS[@]}
do
        echo -e "`date '+%Y-%m-%d %H:%M:%S'`\tQuerying port list from 192.168.60.$I ..."

        $SSH2 192.168.60.$I for i in \`find /opt/HUB/swiftmq/config/smppsvr\_*/ -name routerconfig.xml\`\; do  echo \"\$i\" > $smppresult\_$I\_files.txt \; done\;

        for line in `cat  $smppresult\_$I\_files.txt`
        do
            portname=`echo "$line" | cut -d\_ -f2 | cut -d/ -f1`

            echo -e "`date '+%Y-%m-%d %H:%M:%S'`\tExtracting data from port: $portname in 192.168.60.$I ..."

            $SSH2 192.168.60.$I cat $line > $smppresult\_$I\_$portname.txt

#save active customer list on port
cat $smppresult\_$I\_$portname.txt | sed  '/<!--/,/-->/d' | grep -v "active=\"false\"" | awk -F"swift-queue-tx=\"" '{print $2}' | cut -d_ -f1 | grep -v '^$' | sort -n | uniq > $smppresult\_$I\_$portname\_active.txt

#save commented customer list on port
cat $smppresult\_$I\_$portname.txt | awk 'BEGIN{FS="<!--";RS="-->"}/</{print $2}' |  awk -F"swift-queue-tx=\"" '{print $2}' | cut -d_ -f1 | grep -v '^$' | uniq > $smppresult\_$I\_$portname\_commented.txt
cat $smppresult\_$I\_$portname.txt | sed  '/<!--/,/-->/d' |  grep "active=\"false\"" |  awk -F"swift-queue-tx=\"" '{print $2}' | cut -d_ -f1 | grep -v '^$' | uniq >> $smppresult\_$I\_$portname\_commented.txt
cat $smppresult\_$I\_$portname\_commented.txt | sort -n >  $smppresult\_$I\_$portname\_commented\_temp.txt
cat $smppresult\_$I\_$portname\_commented\_temp.txt | uniq >  $smppresult\_$I\_$portname\_commented.txt

        done
done

echo -e "`date '+%Y-%m-%d %H:%M:%S'`\tExtracting data complete."

counteract=0
countercom=0

for I in ${HOSTS[@]}
do


        #scanning in active configuration
        for filenameact in  $smppresult\_$I\_*\_active.txt
        do
        portnumact=`echo "$filenameact" | cut -d\_ -f3`
        echo -e "`date '+%Y-%m-%d %H:%M:%S'`\tScanning active config for port: $portnumact in 192.168.60.$I ..."
                while read linesqlact
                do
                linesqactcust=`echo $linesqlact | awk '{ print $1 }'`
                linesqactsusp=`echo $linesqlact | awk '{ print $2 }'`
                linesqactclos=`echo $linesqlact | awk '{ print $3 }'`
                                linesqactname=`echo $linesqlact | awk '{ print $4 }'`
                        while read linefileact
                        do
                                if [ "$linesqactcust" == "$linefileact" ]; then
                                counteract=$(( $counteract + 1 ))
                                        if [ "$linesqactsusp" != "NULL" ]; then
                                                echo "<tr><td>$linesqactsusp</td><td>$linesqactcust</td><td>$linesqactname</td><td>Suspended</td><td><font color=\"#ff0000\">Active</font></td><td>192.168.60.$I</td><td>$portnumact</td></tr>" >>$resultbodyact
                                        else
                                                echo "<tr><td>$linesqactclos</td><td>$linesqactcust</td><td>$linesqactname</td><td>Closed</td><td><font color=\"#ff0000\">Active</font></td><td>192.168.60.$I</td><td>$portnumact</td></tr>" >>$resultbodyact
                                        fi
                                fi
                        done < $filenameact
                done < $sqlresult
        done


                #scanning in commented config
                for filenamecom in  $smppresult\_$I\_*\_commented.txt
        do
        portnumcom=`echo "$filenamecom" | cut -d\_ -f3`
        echo -e "`date '+%Y-%m-%d %H:%M:%S'`\tScanning commented config for port: $portnumcom in 192.168.60.$I ..."
                while read linesqlcom
                do
                linesqcomcust=`echo $linesqlcom | awk '{ print $1 }'`
                linesqcomsusp=`echo $linesqlcom | awk '{ print $2 }'`
                linesqcomclos=`echo $linesqlcom | awk '{ print $3 }'`
                linesqcomname=`echo $linesqlcom | awk '{ print $4 }'`
                        while read linefilecom
                        do
                                if [ "$linesqcomcust" == "$linefilecom" ]; then
                                countercom=$(( $countercom + 1 ))

                                        if [ "$linesqcomsusp" != "NULL" ]; then
                                                echo "<tr><td>$linesqcomsusp</td><td>$linesqcomcust</td><td>$linesqcomname</td><td>Suspended</td><td>Inactive</td><td>192.168.60.$I</td><td>$portnumcom</td></tr>" >>$resultbodycom
                                        else
                                                echo "<tr><td>$linesqcomclos</td><td>$linesqcomcust</td><td>$linesqcomname</td><td>Closed</td><td>Inactive</td><td>192.168.60.$I</td><td>$portnumcom</td></tr>" >>$resultbodycom
                                        fi
                                fi
                        done < $filenamecom
                done < $sqlresult
        done


done


echo -e "`date '+%Y-%m-%d %H:%M:%S'`\tGenerating email content ..."
echo "<html>" >$emailbody
echo "<title>CLOSED IXNG CUSTOMER LIST - $DATE</title>" >>$emailbody
echo "<body><font face=\"verdana\" size=\"2\">" >>$emailbody

#adding DB commented info
countquery=`cat $sqlresult | wc -l`
countfound=`expr $counteract + $countercom`
countdiff=`expr $countquery - $countfound`

if [ "$countquery" -lt 0 ]; then
         echo "<p>No Accounts were Suspended/Closed within last week.</p>" >>$emailbody
fi

if [ "$countdiff" -gt 0 ]; then
		 
		 echo "<h5>Customer Account(s) Suspended/Closed during last week</h5><br/>" >> $emailbody
        echo "<table border=\"1\" width=\"80%\"><tr><th>Account ID</th><th>Account Name</th><th>Status in DB</th><th>Suspended/Closed<br/>Date</th></tr>" >> $emailbody

        while read linequery
        do
              custid=`echo $linequery | awk '{ print $1 }'`
              suspended=`echo $linequery | awk '{ print $2 }'`
              closed=`echo $linequery | awk '{ print $3 }'`
			  name=`echo $linequery | awk '{ print $4 }'`

               if [ "$suspended" != "NULL" ]; then
               echo "<tr><td>$custid</td><td>$name</td><td>Suspended</td><td>$suspended</td></tr>" >>$emailbody
              else
                echo "<tr><td>$custid</td><td>$name</td><td>Closed</td><td>$closed</td></tr>" >>$emailbody
              fi

        done < $sqlresult
        echo "</table>" >> $emailbody

fi



#adding active customer list
if [ "$counteract" -gt 0 ]; then
        echo "<p><br/></p>" >> $emailbody
        echo "<h5>Following account(s) are still <font color=\"#ff0000\">ACTIVE</font> in the port configuration file</h5>" >> $emailbody
        echo "<table border=\"1\" width=\"80%\"><tr><th>Suspended/Closed<br/>Date</th><th>Customer ID</th><th>Customer<br/>Name</th><th>Status in DB</th><th>Status in<br/>SMPP Port</th><th>Server IP</th><th>Port</th></tr>" >> $emailbody

        while read lineresultact
        do
                echo $lineresultact >> $emailbody
        done < $resultbodyact
        echo "</table>" >> $emailbody
fi


#adding commented customer list
if [ "$countercom" -gt 0 ]; then

echo "<p><br/></p>"  >> $emailbody
        echo "<h5>Following account(s) are already commented in the port configuration file</h5>" >> $emailbody
        echo "<table border=\"1\" width=\"80%\"><tr><th>Suspended/Closed<br/>Date</th><th>Customer ID</th><th>Customer<br/>Name</th><th>Status in DB</th><th>Status in<br/>SMPP Port</th><th>Server IP</th><th>Port</th></tr>" >> $emailbody

        while read lineresultcom
        do
                echo $lineresultcom >> $emailbody
        done < $resultbodycom
        echo "</table>" >> $emailbody
fi



echo "</font></body></html>" >>$emailbody

#sed 's/$/\n/' $emailbody > $emailbody.linebreak

echo -e "`date '+%Y-%m-%d %H:%M:%S'`\tGenerating email content complete."
echo -e "`date '+%Y-%m-%d %H:%M:%S'`\tSending email ..."

#Send the email
#for emailcontact in `cat /opt/mobileway/etc/emailcontactlist`
for emailcontact in `head -1 /opt/mobileway/etc/emailcontactlist`
do
        /opt/mobileway/scripts/sendhtmlmail.sh $emailcontact $emailbody "Suspended/Closed IXNG Customer Accounts List during last week"
done
echo -e "`date '+%Y-%m-%d %H:%M:%S'`\tEmail sent."

#echo -e "`date '+%Y-%m-%d %H:%M:%S'`\t`rm -v $sqlresult`"
#echo -e "`date '+%Y-%m-%d %H:%M:%S'`\t`rm -v $sqlresultremp`"
#echo -e "`date '+%Y-%m-%d %H:%M:%S'`\t`rm -v $smppresult*`"