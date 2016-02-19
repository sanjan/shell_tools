#!/bin/ksh

SENDMAIL=/usr/sbin/sendmail

subject=`echo $3`
message=`cat $2`
contact=`echo $1`
(
echo "From: sanjan.grero@fr1output2.bd.trust"
echo "To: $contact"
echo "MIME-Version: 1.0"
echo "Content-Type: multipart/mixed;"
echo ' boundary="PAA08673.1018277622/server.domain.com"'
echo "Subject: $subject"
echo ""
echo "This is a MIME-encapsulated message"
echo ""
echo "--PAA08673.1018277622/server.domain.com"
echo "Content-Type: text/html"
echo ""
echo $message
echo "--PAA08673.1018277622/server.domain.com"
) | $SENDMAIL -t

