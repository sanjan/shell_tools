#!/bin/bash

file=$1
threads=/opt/mobileway/tmp/threads.txt
wrkdir=/opt/mobileway/tmp
#zgrep  'submit:\|submit_resp' /opt/mobileway/swiftmq/log/smppsvr_common99/smpp.log.2011-03-09.gz | sort -k3,3 | awk '{print $2" "$3" "$7}' | less

zgrep  'submit:\|submit_resp'  $file | awk '{print $3}' | sort | uniq  | tr -d "[]" > $threads

while read line
do

zgrep  $line  $file | grep 'submit:' >  $wrkdir/$line\_log.txt

zgrep  $line  $file | grep 'submit:\|submit_resp' | sed 's/,/:/' | awk '{print $2}' | awk -F":" '{ hour = $1 *3600000; min = $2 * 60000; sec = $3 * 1000;  sum  = hour + min + sec + $4; print sum }' > $wrkdir/$line.txt



echo -n "" >$wrkdir/$line\_result.txt

value1=0
value2=0
while read value
do

while read submit 
do

value2=$value
expr $value2 - $value1 >>  $wrkdir/$line\_result.txt
value1=$value

done <  $wrkdir/$line.txt

echo $line
echo max delay = `sort -nr  $wrkdir/$line\_result.txt  | head -2 | tail -1`
echo min delay = `sort -n  $wrkdir/$line\_result.txt  | head -1`
echo ""

done < $threads
