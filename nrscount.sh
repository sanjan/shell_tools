#!/bin/bash

hosts=(fr1nrsqn001 fr1nrsqn002)
email="sanjan.grero@sap.com"
hours=(00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23)
yesterday=$(date +'%F' -d '1 day ago')
out=~/$(basename $0 .sh).csv
tempout=~/$(basename $0 .sh).tmp
cp /dev/null ${out}
cp /dev/null ${tempout}
cp /dev/null timeout.csv
#echo "Host Name,Record Type,Country Code,Date,Hour,Count" > $tempout

function cleanup {
rm ${out} ${tempout} timeout.csv
}

for host in ${hosts[@]};
do
fc=$(ssh $host ls -1 /opt/HUB/log/archive/dipLog.log.${yesterday}-[AP]M.gz | wc -l)
if [[ ${fc} -ne 2 ]];then
echo "ERROR: Not all required files exist in ${host}"
cleanup
exit 1
fi
done


for host in ${hosts[@]};
do
echo "Querying: $host ..."
ssh -T ${host} <<EOF | tee -a "${out}"
zgrep -ha 'Sending to dipNode for:60' /opt/HUB/log/archive/dipLog.log.${yesterday}*.gz |cut -d: -f1|sort|uniq -c| awk -v host=\$(hostname) '{print "QUERY,"host",MY,"\$2","\$3","\$1}'
zgrep -ha 'Sending to dipNode for:65' /opt/HUB/log/archive/dipLog.log.${yesterday}*.gz |cut -d: -f1|sort|uniq -c| awk -v host=\$(hostname) '{print "QUERY,"host",SG,"\$2","\$3","\$1}'
zgrep -ha 'Sending to dipNode for:852' /opt/HUB/log/archive/dipLog.log.${yesterday}*.gz |cut -d: -f1|sort|uniq -c| awk -v host=\$(hostname) '{print "QUERY,"host",HK,"\$2","\$3","\$1}'
zgrep -ha 'Dip server timed out -- tn=60' /opt/HUB/log/archive/dipLog.log.${yesterday}*.gz |cut -d: -f1|sort|uniq -c| awk -v host=\$(hostname) '{print "TIMEOUT,"host",MY,"\$2","\$3","\$1}'
zgrep -ha 'Dip server timed out -- tn=65' /opt/HUB/log/archive/dipLog.log.${yesterday}*.gz |cut -d: -f1|sort|uniq -c| awk -v host=\$(hostname) '{print "TIMEOUT,"host",SG,"\$2","\$3","\$1}'
zgrep -ha 'Dip server timed out -- tn=852' /opt/HUB/log/archive/dipLog.log.${yesterday}*.gz |cut -d: -f1|sort|uniq -c| awk -v host=\$(hostname) '{print "TIMEOUT,"host",HK,"\$2","\$3","\$1}'
EOF

done


echo -e "\nProcessing data ...\n"

strings=("TIMEOUT,fr1nrsqn001,MY"
         "TIMEOUT,fr1nrsqn001,SG"
         "TIMEOUT,fr1nrsqn001,HK"
         "TIMEOUT,fr1nrsqn002,MY"
         "TIMEOUT,fr1nrsqn002,SG"
         "TIMEOUT,fr1nrsqn002,HK"
         "QUERY,fr1nrsqn001,MY"
         "QUERY,fr1nrsqn001,SG"
         "QUERY,fr1nrsqn001,HK"
         "QUERY,fr1nrsqn002,MY"
         "QUERY,fr1nrsqn002,SG"
         "QUERY,fr1nrsqn002,HK")
for string in ${strings[@]}
do
for hour in ${hours[@]}
do
output=$(grep "${string},${yesterday},${hour}" ${out})
if [[ "$output" == "" ]]; then
echo "${string},${yesterday},${hour},0" | tee -a "${tempout}"
else
echo ${output} | tee -a "${tempout}"
fi
done

done

echo "Host Name,Country Code,Date,Hour,Total Requests,Timed Out requests,Timed out percentage" > ${out}

sed -i -e '/^TIMEOUT/{w timeout.csv' -e 'd}' ${tempout}


strings2=("fr1nrsqn001,MY"
         "fr1nrsqn001,SG"
         "fr1nrsqn001,HK"
         "fr1nrsqn002,MY"
         "fr1nrsqn002,SG"
         "fr1nrsqn002,HK")

for string in ${strings2[@]}
do
for hour in ${hours[@]}
do
queried=$(grep "${string},${yesterday},${hour}" ${tempout} | cut -d, -f6)
timeout=$(grep "${string},${yesterday},${hour}" timeout.csv | cut -d, -f6)
percentage=$(echo "scale=2; ${timeout} * 100 / ${queried}" | bc)
echo "${string},${yesterday},${hour},${queried},${timeout},${percentage}%" | tee -a "${out}"
done
done



echo "Sending email to ${email} ..."
echo "Please check the attached" | mutt -a ${out} -s "NRS Dip Count for MY,SG,HK - ${yesterday}" -- ${email}
cleanup
echo "Complete!"

