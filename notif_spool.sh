#!/bin/sh

ALLNOTIFHOSTS=( fr1notif001 fr1notif002 fr1notif003 fr1notif004	fr1notif005 fr1notif006	fr1notif007 fr1notif008	fr1notif009 fr1notif010	fr1notif101 fr1notif102	fr1notif103 fr1notif104	fr1mtrouter009 fr1mtrouter010 )
NOTIFMAINHOSTS=( fr1notif001 fr1notif002 fr1notif003 fr1notif004 fr1notif005 fr1notif006 fr1notif007 fr1notif008 fr1notif009 fr1notif010 fr1mtrouter009 fr1mtrouter010 )
NOTIFL1MAINHOSTS=( fr1notif001 fr1notif002 fr1notif003	fr1notif004 )
NOTIFL2MAINHOSTS=( fr1notif005 fr1notif006 fr1notif007	fr1notif008 fr1notif009	fr1notif010 fr1mtrouter009 fr1mtrouter010 )
NOTIFTSSHOSTS=( fr1notif101 fr1notif102 fr1notif103 fr1notif104 )
NOTIFL1TSSHOSTS=( fr1notif101 fr1notif102 )
NOTIFL2TSSHOSTS=( fr1notif103 fr1notif104 )
ALLL1NOTIFHOSTS=( fr1notif001 fr1notif002 fr1notif003 fr1notif004 fr1notif101 fr1notif102 )
ALLL2NOTIFHOSTS=( fr1notif005 fr1notif006 fr1notif007 fr1notif008 fr1notif009 fr1notif010 fr1mtrouter009 fr1mtrouter010 fr1notif103 fr1notif104 )
ALLUKNOTIF=( uk4notifa01 uk4notifa02 uk4notifb01 uk4notifb02 )
UKL1NOTIF=( uk4notifa01 uk4notifa02 )
UKL2NOTIF=( uk4notifb01 uk4notifb02 )
echo
echo FR1 MAIN HUB
for i in ${NOTIFMAINHOSTS[@]}
do 
echo $i:
ssh production1@$i for i in \`find /opt/HUB/NOTIF/ -type d 2\>/dev/null \| grep \'updatemtnotif\\\|notifsendsms\'\`\;do j=\`find \$i -maxdepth 1 -type f 2\>/dev/null \| wc -l\`\; echo -e \$j\'\\t:\'\$i\;done \| grep -v ^0 \| sort -nk1,1 | tail -n10
echo
done
echo FR1 TSS HUB
for i in ${NOTIFTSSHOSTS[@]}
do
echo $i:
ssh production1@$i for i in \`find /opt/HUB/NOTIF/ -type d 2\>/dev/null \| grep \'updatemtnotif\\\|notifsendsms\'\`\;do j=\`find \$i -maxdepth 1 -type f 2\>/dev/null \| wc -l\`\; echo -e \$j\'\\t:\'\$i\;done \| grep -v ^0 \| sort -nk1,1
echo
done
echo UK4 HUB
for i in ${ALLUKNOTIF[@]}
do
echo $i:
ssh production1@$i for i in \`find /opt/HUB/NOTIF/ -type d 2\>/dev/null \| grep \'updatemtnotif\\\|notifsendsms\'\`\;do j=\`find \$i -maxdepth 1 -type f 2\>/dev/null \| wc -l\`\; echo -e \$j\'\\t:\'\$i\;done \| grep -v ^0 \| sort -nk1,1
echo
done

echo "Processing complete."

