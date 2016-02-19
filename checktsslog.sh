#!/bin/sh

j=`date --date="1 minute ago" "+%d %I:%M"`;
#j="29 06:05"
echo `date "+%Y-%m-%d %H:%M:%S" `" - " "Time Now: " `date`
echo `date "+%Y-%m-%d %H:%M:%S"`" - " "Time 1 min ago: " `date --date="1 minute ago"`
echo `date "+%Y-%m-%d %H:%M:%S"`" - " "Checking SMPP Conections"
for i in `lc fullstatus 2>/dev/null | grep ^logfile | awk '{print $2}' | grep -i ixng | grep -i smpp`;
do

        k=`grep -a "enquirelink_resp:" $i | grep "$j" | tail -n1 | wc -l`;
        #echo "k=AAAAA"$k"AAAA";
        #m=`echo $k | wc -l`;
        #echo $m;
                if [ "$k" -ne "1" ];then
                echo `date "+%Y-%m-%d %H:%M:%S"`" - " "$i : NOT UPDATED";
                else
                echo `date "+%Y-%m-%d %H:%M:%S"`" - " "$i : OK";
                fi;
done
echo
echo `date "+%Y-%m-%d %H:%M:%S"`" - " "Checking HTTP  Conections"
for i in `lc fullstatus 2>/dev/null | grep ^logfile | awk '{print $2}' | grep -i ixng | grep -i http`;
do

        k=`grep -a -i -B1 "http/1.1.*200.*ok" $i | tail -n2 | grep -v "Comp\|xml\|>>"`;
        #echo "k=AAAAA"$k"AAAA";
       m=`echo $k | wc -l`;
        #echo $m;
                if [ "$m" -lt "1" ];then
                echo `date "+%Y-%m-%d %H:%M:%S"`" - " "$i : $k NOT UPDATED";
                else
                echo `date "+%Y-%m-%d %H:%M:%S"`" - " "$i : $k";
                fi;
echo
done
echo `date "+%Y-%m-%d %H:%M:%S"`" - Completed"
