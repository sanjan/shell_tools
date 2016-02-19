#!/bin/bash

hosts=(fr1nrsqn001 fr1nrsqn002)
email="sanjan.grero@sap.com"
hours=(00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23)
yesterday=$(date +'%Y-%m-%d' -d '1 day ago')
out=~/$(basename $0 .sh).tmp
finaloutput=~/$(basename $0 .sh).csv
cp /dev/null $out
echo "Host Name,Record Type,Country Code,Date,Hour,Count" > $finaloutput

for host in ${hosts[@]};
do
echo "Querying: $host ..."
ssh -T $host <<EOF | tee -a "${out}"

date=\$(date +'%Y-%m-%d' -d '1 day ago')

zgrep -ha 'Sending to dipNode for:60' /opt/HUB/log/archive/dipLog.log.\${date}*.gz |cut -d: -f1|sort|uniq -c| awk -v host=\$(hostname) '{print host",QUERY,MY,"\$2","\$3","\$1}'
zgrep -ha 'Sending to dipNode for:65' /opt/HUB/log/archive/dipLog.log.\${date}*.gz |cut -d: -f1|sort|uniq -c| awk -v host=\$(hostname) '{print host",QUERY,SG,"\$2","\$3","\$1}'
zgrep -ha 'Sending to dipNode for:852' /opt/HUB/log/archive/dipLog.log.\${date}*.gz |cut -d: -f1|sort|uniq -c| awk -v host=\$(hostname) '{print host",QUERY,HK,"\$2","\$3","\$1}'
zgrep -ha 'Dip server timed out -- tn=60' /opt/HUB/log/archive/dipLog.log.\${date}*.gz |cut -d: -f1|sort|uniq -c| awk -v host=\$(hostname) '{print host",TIMEOUT,MY,"\$2","\$3","\$1}'
zgrep -ha 'Dip server timed out -- tn=65' /opt/HUB/log/archive/dipLog.log.\${date}*.gz |cut -d: -f1|sort|uniq -c| awk -v host=\$(hostname) '{print host",TIMEOUT,SG,"\$2","\$3","\$1}'
zgrep -ha 'Dip server timed out -- tn=852' /opt/HUB/log/archive/dipLog.log.\${date}*.gz |cut -d: -f1|sort|uniq -c| awk -v host=\$(hostname) '{print host",TIMEOUT,HK,"\$2","\$3","\$1}'
EOF
done

echo -e "\nProcessing data ...\n"

strings=("fr1nrsqn001,TIMEOUT,MY"
		 "fr1nrsqn001,TIMEOUT,SG"
		 "fr1nrsqn001,TIMEOUT,HK"
		 "fr1nrsqn002,TIMEOUT,MY" 
		 "fr1nrsqn002,TIMEOUT,SG"
		 "fr1nrsqn002,TIMEOUT,HK"
		 "fr1nrsqn001,QUERY,MY" 
		 "fr1nrsqn001,QUERY,SG"
		 "fr1nrsqn001,QUERY,HK"
		 "fr1nrsqn002,QUERY,MY" 
		 "fr1nrsqn002,QUERY,SG"
		 "fr1nrsqn002,QUERY,HK"
		 )
for string in ${strings[@]}
do
for hour in ${hours[@]}
do
output=$(grep "${string},${yesterday},${hour}" ${out})
if [[ "$output" == "" ]]; then
echo "${string},${yesterday},${hour},0" | tee -a "${finaloutput}"
else
echo $output  | tee -a "${finaloutput}"
fi
done

done

echo "Sending email to ${email} ..."
echo "Please check the attached" | mutt -a ${finaloutput} -s "NRS Dip Count for MY,SG,HK" -- $email
echo "Complete!"
