#!/bin/ksh

##############################################################################################################################################
# My Variables

# MTRouter
my_fr1_mtrouters_main='fr1mtrouter001 fr1mtrouter002 fr1mtrouter003 fr1mtrouter004 fr1mtrouter005 fr1mtrouter006 
fr1mtrouter007 fr1mtrouter008 fr1mtrouter009 fr1mtrouter010 fr1mtrouter011 fr1mtrouter012 fr1mtrouter013 fr1mtrouter014'
my_fr1_mtrouters_tss='fr1mtrouter101 fr1mtrouter102'
mtrouter_input_folder='/opt/HUB/router/inputspool'
mtrouter_resendable_folder='/opt/HUB/router/error/resendable'
mtrouter_error_default='/opt/HUB/router/error/default'

# Notifs
my_fr1_notifs_lvl1_main='fr1notif001 fr1notif002 fr1notif003 fr1notif004'
my_fr1_notifs_lvl1_tss='fr1notif101 fr1notif102'
my_fr1_notifs_lvl2_3_main='fr1notif005 fr1notif006 fr1notif007 fr1notif008 fr1notif009 fr1notif010 fr1notif011 fr1notif012'
my_fr1_notifs_lvl2_3_tss='fr1notif103 fr1notif104'

# MORouters
my_fr1_morouter_main='fr1morouter001 fr1morouter002'
my_fr1_morouter_tss='fr1morouter101 fr1morouter102'
morouter_input_folder='/opt/mobileway/mo_notifications/inputspool'
morouter_error_folder='/opt/mobileway/mo_notifications/error'

# Orderid servers
my_orderid='fr1orderid001 fr1orderid002'

# UK4
my_uk4_mtrouters='uk4mtrouter01 uk4mtrouter02 uk4mtrouter003'
my_uk4_lv1_notifs='uk4notifa01 uk4notifa02'
my_uk4_lv2_notifs='uk4notifb01 uk4notifb02'
my_uk4_morouters='uk4morouter01 uk4morouter02'
my_uk4_orderid='uk4orderid01 uk4orderid02'

#Connection servers
my_fr1cnx='fr1cnx01 fr1cnx02 fr1cnx03 fr1cnx04 fr1cnx06 fr1cnx07 fr1cnx08 fr1cnx09 fr1cnx10 fr1cnx11 fr1cnx12 fr1cnx13 fr1cnx14 fr1cnx15 fr1cnx16 fr1cnx18 fr1cnx19 fr1cnx20 fr1cnx21 fr1cnx22 fr1cnx23 fr1cnx24 fr1cnx25 fr1cnx26 fr1cnx27 fr1cnx28'

my_new_fr1cnx='fr1cnx001 fr1cnx002 fr1cnx003 fr1cnx004 fr1cnx005 fr1cnx006 fr1cnx007 fr1cnx008 fr1cnx009 fr1cnx010 fr1cnx011 fr1cnx012 fr1cnx013 fr1cnx014 fr1cnx015 fr1cnx016 fr1cnx017 fr1cnx018 fr1cnx019 fr1cnx020 fr1cnx021 fr1cnx022 fr1cnx023 fr1cnx024 fr1cnx025 fr1cnx026 fr1cnx028 fr1cnx030 fr1cnx032 fr1cnx034 fr1cnx036 fr1cnx038 fr1cnx040 fr1cnx042 fr1cnx044 fr1cnx046 fr1cnx048 fr1cnx101 fr1cnx103 fr1cnx104 fr1cnx105 fr1cnx106'

my_libspec='fr1cnx02 fr1cnx03 fr1cnx04 fr1cnx06 fr1cnx07 fr1cnx08 fr1cnx10 fr1cnx11 fr1cnx12 fr1cnx13 fr1cnx14 fr1cnx21 fr1cnx22 fr1cnx23 fr1cnx24 fr1cnx27'

##############################################################################################################################################

function pause
{

OLDCONFIG=`stty -g`

stty -icanon -echo min 1 time 0
dd count=1 2>/dev/null

stty $OLDCONFIG

}



function checklc
{
echo "Checking Running Lance Processes"
echo ""
for host in $*
do
echo "Executing on [$host]"
echo -n "Press any key to continue... "
pause
echo ""
ssh production1@$host 'echo "Lance Processes: ";/opt/HUB/bin/lc status;echo "";echo -n "Do you want to see ps command output for production1 user (y/n)?";read ans;if [[ $ans == "y" ]];then ps auxfwww | grep ^517;fi'
echo ""
done
}

function startlc
{
echo "Starting/Restarting Lance Processes"
echo ""
for host in $*
do
echo "[$host]"
ssh production1@$host 'i=`/opt/HUB/bin/lc status | wc -l`;j=`/opt/HUB/bin/lc nok | wc -l`;if [[ $i -eq 1 ]];then /opt/HUB/bin/lc start;elif [[ $j -gt 0 ]]; then /opt/HUB/bin/lc reconf;else echo "All lance processes are already running on this server.";fi'
echo ""
done
}

function stoplc
{
echo -n "Are you sure you want to stop all lance processes (yes/no)? "
read answer
if [[ $answer == "yes" ]]; then
echo ""
echo "Stopping All Lance Processes"
echo ""
for host in $*
do
echo "[$host]"
ssh production1@$host 'i=`/opt/HUB/bin/lc status | wc -l`;if [[ $i -gt 1 ]];then /opt/HUB/bin/lc stop all;else echo "All lance processes are already STOPPED on this server.";fi'
echo ""
done
fi
}

function diskspacecheck
{
for host in $*
do
echo -n $host": "
ssh production1@$host  df -h --portability /opt | tail -n1 |awk '{ print "Total diskspace /opt  (used+free):  " $3 " ("$5") + " $4 " = " $2 }'
done
}

function uptime
{
for host in $*
do
ssh production1@$host  'echo `hostname`": " `uptime | cut -d, -f4-6`'
done
}

function memory
{
for host in $*
do
echo -n $host": "
ssh production1@$host   free -m | grep "Mem:" | awk '{ print "Total physical memory (used+free): " $3 " + " $4 " = " $2 }'; 
done
}

function swapmemory
{
for host in $*
do
echo -n $host": "
ssh production1@$host   free -m | grep "Swap:" | awk '{ print "Total swap memory (used+free): " $3 " + " $4 " = " $2 }'; 
done
}

function sarcpu
{
for host in $*
do
echo -n $host": "
ssh production1@$host  sar | tail -n2 | head -n1 | awk '{ if ($2 == "all") printf "user: " $3"%, system: "$5"%, iowait: "$6"%, idle: ";else printf "user: " $4"%, system: "$6"%, iowait: "$7"%, idle: "; if ($2 == "all" && $8== "") printf $7; else if ($9 == "") printf $8; else printf $9; printf "%\n"}'
done
}

function checklibspec
{
for host in $my_libspec
#for host in $*
do
echo "Host: "$host
echo
#ssh production1@$host  '/opt/mobileway/bin/lc status 2>/dev/null | grep -i "surem"'
ssh production1@$host  '/opt/mobileway/bin/lc status 2>/dev/null | grep -i -v libspec | grep -v -i ixng | grep -v -i sock | grep -v -i sendsms | grep -v -i filter | grep -v -i retry'
echo
done
}

function restartmtrouter
{
for host in $*
do
echo "Host: "$host
echo
ssh production1@$host '/opt/HUB/bin/lc stop JMTRouter; sleep 2; k=`/opt/HUB/bin/lc nok | grep JMTRouter | wc -l`;echo "Stopped $k MT Router processes"; if [ $k == 0 ]; then echo "Stopping Router Again... "; /opt/HUB/bin/lc stop JMTRouter;sleep 5;fi;/opt/HUB/bin/lc reconf'
echo
done
}

function dtw_spoolmanager
{
for host in $*
do
echo "Host: "$host
echo
ssh production1@$host '/opt/HUB/bin/lc stop dtw_spoolmanager; sleep 2; k=`/opt/HUB/bin/lc nok | grep dtw_spoolmanager | wc -l`;echo "Stopped $k dtw_spoolmanager processes"; if [ $k == 0 ]; then echo "Stopping dtw_spoolmanager Again... "; /opt/HUB/bin/lc stop dtw_spoolmanager;sleep 5;fi;/opt/HUB/bin/lc reconf'
echo
done
}



function stoplibspec
{
while true
do
echo -n "Enter hostname(E to exit):"
read host
if [[ $host == "E" ]]; then
break
else
echo "Host: "$host
echo -n "Are you sure you want to stop libspec processes in $host (y/n)? "
read answer
if [[ $answer == "y" ]]; then
echo
ssh production1@$host  'for i in $( /opt/mobileway/bin/lc status 2>/dev/null | grep -i "libspec\|mwapi" | awk "{print \$1}" );do /opt/mobileway/bin/lc stop $i;done'
echo
fi
fi
done
}

function startlibspec
{
while true
do
echo -n "Enter hostname(E to exit):"
read host
if [[ $host == "E" ]]; then
break
else
echo "Host: "$host
echo -n "Are you sure you want to start libspec processes in $host (y/n)? "
read answer
if [[ $answer == "y" ]]; then
echo
ssh production1@$host  '/opt/mobileway/bin/lc reconf'
echo
fi
fi
done
}

function custcommand
{
echo -n "Enter command: "
read  answer
echo "executing command: "${answer}
for host in $*
do
echo -e "\nHost: "$host
echo
ssh -T production1@${host} ${answer}
echo
done

}


clear
echo ""
echo "======================="
echo "| Batch Start/Stop V1 |"
echo "======================="
echo ""
export COLUMNS=1
PS3="Pick a number (Press ENTER to display menu): "
echo ""
select menu_selections in "Check running lance processes in Main HUB MT Routers" "Check running lance processes in TSS HUB MT Routers" "Check running lance processes in Main HUB MO Routers" "Check running lance processes in TSS HUB MO Routers" "Check running lance processes in Main HUB Notif Routers" "Check running lance processes in TSS HUB Notif Routers" "Start/Restart lance processes in Main HUB MT Routers" "Start/Restart lance processes in TSS HUB MT Routers" "Start/Restart lance processes in Main HUB MO Routers" "Start/Restart lance processes in TSS HUB MO Routers" "Start/restart lance processes in Main HUB Notif Routers" "Start/restart lance processes in TSS HUB Notif Routers" "Stop all lance processes in Main HUB MT Routers" "Stop all lance processes in Main HUB MO Routers" "Stop all lance processes in TSS HUB MO Routers"  "Stop all lance processes in Main HUB Notif Routers" "Stop all lance processes in TSS HUB Notif Routers" "Check /opt disk space usage for All servers" "Check load average on All servers" "Check CPU usage on All servers" "Check physical memory usage on All servers" "Check swap memory usage on All servers" "Check running libspec connections" "Stop libspec connections" "Start libspec connections" "Custom Command: Legacy CNX Servers" "Custom Command: NG CNX Servers" "Restart FR1 MT Router Process" "Restart FR1 dtw_spoolmanager process" QUIT
do
case $menu_selections in
"Check running lance processes in Main HUB MT Routers") checklc "$my_fr1_mtrouters_main"
;;
"Check running lance processes in TSS HUB MT Routers") checklc "$my_fr1_mtrouters_tss"
;;
"Check running lance processes in Main HUB MO Routers") checklc "$my_fr1_morouter_main"
;;
"Check running lance processes in TSS HUB MO Routers") checklc "$my_fr1_morouter_tss"
;;
"Check running lance processes in Main HUB Notif Routers") checklc "$my_fr1_notifs_lvl1_main $my_fr1_notifs_lvl2_3_main"
;;
"Check running lance processes in TSS HUB Notif Routers") checklc "$my_fr1_notifs_lvl1_tss $my_fr1_notifs_lvl2_3_tss"
;;
"Start/Restart lance processes in Main HUB MT Routers") startlc "$my_fr1_mtrouters_main"
;;
"Start/Restart lance processes in TSS HUB MT Routers") startlc "$my_fr1_mtrouters_tss"
;;
"Start/Restart lance processes in Main HUB MO Routers") startlc "$my_fr1_morouter_main"
;;
"Start/Restart lance processes in TSS HUB MO Routers") startlc "$my_fr1_morouter_tss"
;;
"Start/restart lance processes in Main HUB Notif Routers") startlc "$my_fr1_notifs_lvl1_main $my_fr1_notifs_lvl2_3_main"
;;
"Start/restart lance processes in TSS HUB Notif Routers") startlc "$my_fr1_notifs_lvl1_tss $my_fr1_notifs_lvl2_3_tss"
;;
"Stop all lance processes in Main HUB MT Routers") stoplc "$my_fr1_mtrouters_main"
;;
"Stop all lance processes in TSS HUB MT Routers") stoplc "$my_fr1_mtrouters_tss"
;;
"Stop all lance processes in Main HUB MO Routers") stoplc "$my_fr1_morouter_main"
;;
"Stop all lance processes in TSS HUB MO Routers") stoplc "$my_fr1_morouter_tss"
;;
"Stop all lance processes in Main HUB Notif Routers") stoplc "$my_fr1_notifs_lvl1_main $my_fr1_notifs_lvl2_3_main"
;;
"Stop all lance processes in TSS HUB Notif Routers") stoplc "$my_fr1_notifs_lvl1_tss $my_fr1_notifs_lvl2_3_tss"
;;
"Check /opt disk space usage for All servers") diskspacecheck "$my_fr1_mtrouters_main $my_fr1_mtrouters_tss $my_fr1_morouter_main $my_fr1_morouter_tss $my_fr1_notifs_lvl1_main $my_fr1_notifs_lvl2_3_main $my_fr1_notifs_lvl1_tss $my_fr1_notifs_lvl2_3_tss $my_fr1cnx $my_new_fr1cnx"
;;
"Check load average on All servers") uptime "$my_fr1_mtrouters_main $my_fr1_mtrouters_tss $my_fr1_morouter_main $my_fr1_morouter_tss $my_fr1_notifs_lvl1_main $my_fr1_notifs_lvl2_3_main $my_fr1_notifs_lvl1_tss $my_fr1_notifs_lvl2_3_tss $my_fr1cnx $my_new_fr1cnx"
;;
"Check CPU usage on All servers") sarcpu "$my_fr1_mtrouters_main $my_fr1_mtrouters_tss $my_fr1_morouter_main $my_fr1_morouter_tss $my_fr1_notifs_lvl1_main $my_fr1_notifs_lvl2_3_main $my_fr1_notifs_lvl1_tss $my_fr1_notifs_lvl2_3_tss $my_fr1cnx  $my_new_fr1cnx"
;;
"Check physical memory usage on All servers") memory "$my_fr1_mtrouters_main $my_fr1_mtrouters_tss $my_fr1_morouter_main $my_fr1_morouter_tss $my_fr1_notifs_lvl1_main $my_fr1_notifs_lvl2_3_main $my_fr1_notifs_lvl1_tss $my_fr1_notifs_lvl2_3_tss $my_fr1cnx  $my_new_fr1cnx"
;;
"Check swap memory usage on All servers") swapmemory "$my_fr1_mtrouters_main $my_fr1_mtrouters_tss $my_fr1_morouter_main $my_fr1_morouter_tss $my_fr1_notifs_lvl1_main $my_fr1_notifs_lvl2_3_main $my_fr1_notifs_lvl1_tss $my_fr1_notifs_lvl2_3_tss $my_fr1cnx  $my_new_fr1cnx"
;;
"Check running libspec connections") checklibspec "$my_fr1cnx $my_new_fr1cnx" 
;;
"Stop libspec connections") stoplibspec "$my_fr1cnx $my_new_fr1cnx"
;;
"Start libspec connections") startlibspec "$my_fr1cnx $my_new_fr1cnx"
;;
"Custom Command: Legacy CNX Servers") custcommand "$my_fr1cnx"
;;
"Custom Command: NG CNX Servers") custcommand "$my_new_fr1cnx"
;;
"Restart FR1 MT Router Process") restartmtrouter "$my_fr1_mtrouters_main $my_fr1_mtrouters_tss"
;;
"Restart FR1 dtw_spoolmanager Process") dtw_spoolmanager "$my_fr1_mtrouters_main $my_fr1_mtrouters_tss"
;;
QUIT) print "\nGoodbye!\n"
break
;;
*) print "\nInvalid Entry - Try Again!\n"
;;
esac
echo ""
done
