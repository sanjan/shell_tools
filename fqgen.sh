#!/bin/sh

echo "fair queue msg generation script"
echo "================================"

echo "stopping file2jms-mtrouter process"
/opt/HUB/bin/lc stop file2jms-mtrouter  2>/dev/null
sleep 3;

#check if stopped
chk=`lc nok | grep file2jms | wc -l`

if [ $chk -eq 1 ];then

smscid=8380
echo
echo -n "Enter number of customers: "
read numcust

COUNTER=1
while [  $COUNTER -le $numcust ]; do
    	 
echo -n "Enter customer id for customer [$COUNTER]: "
read customerid
echo -n "Enter message count for customer [$COUNTER]: "
read msgcount

echo "generating messages for customer $customerid ..."

mcounter=0

while [ $mcounter -lt $msgcount ]; do

date=`TZ=GMT-2 date +%Y%m%d%H%M%S`

file=$date-$mcounter-1-$mcounter-$customerid-$smscid-4510.txt
 
echo "[MAILORDER]
CustomerId=$customerid
Class=1
DCS=0
MobileNotify=0
MailAckType=0
ValidityPeriod=168
GuaranteedDeliveryTime=0
DeferredDeliveryTime=0
PID=00
MsgLen=21
Message=FAIR QUEUE TEST $customerid
MailSubject=
MailReply=
TpOa=74534
NotifIpAddr=10.150.7.22
NotifIpPort=0
MoreMsgToSend=1
ReplyPath=0
StatusReportIndication=
Priority=0
UDHI=0
UDH=
OrderId=1468784904
SubmittedTime=$date
Operator=
Protocol=
OptionField=0
WindowDeliveryTime=
[MSISDN]
List=+12108449375
[LIBRARY_DATA]
Cmd=51
DestinationAddr=+12108449375
OriginatingAddr=74534
NotifRequest=0
NotifAddr=127.0.0.1
NotifPort=11691
SmscId=$smscid
ValidityPeriod=168
EncodingType=0
MessageClass=1
PID=0
Connection=0
DeferredDeliveryTime=0
MoreMsgSend=1
ReplyPath=0
StatusReportIndication=0
Priority=0
MsgLen=21
Message=FAIR QUEUE TEST $customerid
UDHI=0
UDH=
[MESSAGE]
MessageId=1
SequenceNo=146878490400001
ProofOfReceipt=0
Msisdn=+12108449375
TpOa=74534
SmscId=$smscid
SmscDeliveryTime=
MeDeliveryTime=
Status=4510
OperatorId=78
[SMSC]
SmscId=$smscid
Country=60
OperatorId=78
ValidityPeriod=173
TpOa=1234
InterConnectTime=0
ProofOfReceipt=1
NotifIpAddress=127.0.0.1
NotifIpPort=11691
MoIpAddress=
MoIpPort=0
SmscType=999
DynamicTpOa=1
ManagedByMailServer=0
ManagedUDH=1
SmscUDH=0" > /opt/HUB/router/outputspool_real/$smscid/$file

let mcounter=mcounter+1

done

echo "completed generating $mcounter messages for customer: $customerid"

let COUNTER=COUNTER+1 
	
done

fi

spool=`ls -F /opt/HUB/router/outputspool_real/$smscid/ | wc -l`
echo "spool at $smscid: $spool"
echo
echo "starting file2jms-mtrouter process"
/opt/HUB/bin/lc reconf  2>/dev/null

