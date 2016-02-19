#!/bin/bash

hosts=(fr1nrsqn001 fr1nrsqn002)
email="jemielyn.angeles@sap.com"
out=~/$(basename $0 .sh).csv
echo "Host Name,Record Type,Country Code,Count,Date,Hour" > $out

for host in ${hosts[@]};
do
echo "Querying: $host ..."
ssh -T $host <<EOF | tee -a "${out}"

date=\$(date +'%Y-%m-%d' -d '1 day ago')
hours=(00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23)
for hour in \${hours[@]}
do

output=\$(zgrep -ha 'Sending to dipNode for:60' /opt/HUB/log/archive/dipLog.log.\${date}*.gz |cut -d: -f1|sort|uniq -c | grep " \${hour}$")
if [[ "\$output" != "" ]];then
echo \$output | awk -v host=\$(hostname) '{print host",QUERY,MY,"\$2","\$3","\$1}'
else
echo "\$(hostname),QUERY,MY,\${date},\${hour},0"
fi

output=\$(zgrep -ha 'Sending to dipNode for:65' /opt/HUB/log/archive/dipLog.log.\${date}*.gz |cut -d: -f1|sort|uniq -c | grep " \${hour}$")
if [[ "\$output" != "" ]];then
echo \$output | awk -v host=\$(hostname) '{print host",QUERY,SG,"\$2","\$3","\$1}'
else
echo "\$(hostname),QUERY,SG,\${date},\${hour},0"
fi

output=\$(zgrep -ha 'Sending to dipNode for:852' /opt/HUB/log/archive/dipLog.log.\${date}*.gz |cut -d: -f1|sort|uniq -c | grep " \${hour}$")
if [[ "\$output" != "" ]];then
echo \$output | awk -v host=\$(hostname) '{print host",QUERY,HK,"\$2","\$3","\$1}'
else
echo "\$(hostname),QUERY,HK,\${date},\${hour},0"
fi

output=\$(zgrep -ha 'Dip server timed out -- tn=60' /opt/HUB/log/archive/dipLog.log.\${date}*.gz |cut -d: -f1|sort|uniq -c | grep " \${hour}$")
if [[ "\$output" != "" ]];then
echo \$output | awk -v host=\$(hostname) '{print host",TIMEOUT,MY,"\$2","\$3","\$1}'
else
echo "\$(hostname),TIMEOUT,MY,\${date},\${hour},0"
fi

output=\$(zgrep -ha 'Dip server timed out -- tn=65' /opt/HUB/log/archive/dipLog.log.\${date}*.gz |cut -d: -f1|sort|uniq -c | grep " \${hour}$")
if [[ "\$output" != "" ]];then
echo \$output | awk -v host=\$(hostname) '{print host",TIMEOUT,SG,"\$2","\$3","\$1}'
else
echo "\$(hostname),TIMEOUT,SG,\${date},\${hour},0"
fi

output=\$(zgrep -ha 'Dip server timed out -- tn=852' /opt/HUB/log/archive/dipLog.log.\${date}*.gz |cut -d: -f1|sort|uniq -c | grep " \${hour}$")
if [[ "\$output" != "" ]];then
echo \$output | awk -v host=\$(hostname) '{print host",TIMEOUT,HK,"\$2","\$3","\$1}'
else
echo "\$(hostname),TIMEOUT,HK,\${date},\${hour},0"
fi

done

EOF
done

echo "Sending email to ${email} ..."
echo "Please check the attached" | mutt -a ${out} -s "NRS Dip Count for MY,SG,HK" -- $email
