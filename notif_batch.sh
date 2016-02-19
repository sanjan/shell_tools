#!/bin/sh

ALLNOTIFHOSTS=( fr1notif001 fr1notif002 fr1notif003 fr1notif004	fr1notif005 fr1notif006	fr1notif007 fr1notif008	fr1notif009 fr1notif010	fr1notif101 fr1notif102	fr1notif103 fr1notif104 fr1notif011 fr1notif012	)
NOTIFMAINHOSTS=( fr1notif001 fr1notif002 fr1notif003 fr1notif004 fr1notif005 fr1notif006 fr1notif007 fr1notif008 fr1notif009 fr1notif010 fr1notif011 fr1notif012 )
NOTIFL1MAINHOSTS=( fr1notif001 fr1notif002 fr1notif003	fr1notif004 )
NOTIFL2MAINHOSTS=( fr1notif005 fr1notif006 fr1notif007	fr1notif008 fr1notif009	fr1notif010 fr1notif011 fr1notif012 )
NOTIFTSSHOSTS=( fr1notif101 fr1notif102 fr1notif103 fr1notif104 )
NOTIFL1TSSHOSTS=( fr1notif101 fr1notif102 )
NOTIFL2TSSHOSTS=( fr1notif103 fr1notif104 )
ALLL1NOTIFHOSTS=( fr1notif001 fr1notif002 fr1notif003 fr1notif004 fr1notif101 fr1notif102 )
ALLL2NOTIFHOSTS=( fr1notif005 fr1notif006 fr1notif007 fr1notif008 fr1notif009 fr1notif010 fr1notif011 fr1notif012 fr1notif103 fr1notif104 )
ALLUKNOTIF=( uk4notifa01 uk4notifa02 uk4notifb01 uk4notifb02 )
UKL1NOTIF=( uk4notifa01 uk4notifa02 )
UKL2NOTIF=( uk4notifb01 uk4notifb02 )
ALL=( fr1notif001 fr1notif002 fr1notif003 fr1notif004 fr1notif005 fr1notif006 fr1notif007 fr1notif008 fr1notif009 fr1notif010 fr1notif101 fr1notif102 fr1notif103 fr1notif104 uk4notifa01 uk4notifa02 uk4notifb01 uk4notifb02 fr1notif011 fr1notif012 )
SPARE=( )
#SPARE=( fr1notif011 fr1notif012 )
CUTOVERSTEP6=( fr1notif001 fr1notif002 fr1notif003  fr1notif004 fr1notif101 fr1notif102 )
MOHOSTS=( fr1morouter001 fr1morouter002 )
declare -a hostsarray

declare cmd
declare cmdtype

while [ "${hostsarray[0]}" == "" ]
do

echo "Hosts Range:"
echo
echo '1) ALL FR1 (MAIN & TSS) & SPARE'
echo
echo '2) FR1 MAIN (L1 & L2 & SPARE)'
echo '3) FR1 MAIN L1 ONLY'
echo '4) FR1 MAIN L2 ONLY'
echo
echo '5) FR1 TSS (L1 & L2)'
echo '6) FR1 TSS L1 ONLY'
echo '7) FR1 TSS L2 ONLY'
echo
echo '8) FR1 MAIN & TSS L1 ONLY'
echo '9) FR1 MAIN & TSS L2 ONLY'
echo
echo '10) All UK4'
echo '11) UK4 L1 ONLY'
echo '12) UK4 L2 ONLY'
echo
echo '13) ALL SERVERS FR1, UK4 & SPARE'
echo '14) ONLY SPARE servers'
echo
echo '15) FR1 MAIN HUB LVL 1, TSS HUB LVL 1 and SPARE SERVERS (CUTOVER 6)'
echo '16) mo routers'
echo 'x) EXIT'
echo 
echo -n 'Enter your selection: '
read choice
echo


case $choice in
        1)
        hostsarray=${ALLNOTIFHOSTS[@]}
		echo 'You selected: All FR1 notif servers'
        ;;
        2)
        hostsarray=${NOTIFMAINHOSTS[@]}
		echo 'You selected: Main hub lvl 1 & lvl 2 notif servers'
        ;;
        3)
        hostsarray=${NOTIFL1MAINHOSTS[@]}
		echo 'You selected: Main hub lvl 1 notif servers'
        ;;
        4)
        hostsarray=${NOTIFL2MAINHOSTS[@]}
		echo 'You selected: Main hub lvl 2 notif servers'
        ;;
        5)
        hostsarray=${NOTIFTSSHOSTS[@]}
		echo 'You selected: TSS hub lvl 1 & lvl 2 notif servers'
        ;;
        6)
        hostsarray=${NOTIFL1TSSHOSTS[@]}
		echo 'You selected: TSS hub lvl 1 notif servers'
        ;;
        7)
        hostsarray=${NOTIFL2TSSHOSTS[@]}
		echo 'You selected: TSS hub lvl 2 notif servers'
        ;;
	8)
        hostsarray=${ALLL1NOTIFHOSTS[@]}
		echo 'You selected: Main & TSS hub lvl 1 notif servers'
        ;;
        9)
        hostsarray=${ALLL2NOTIFHOSTS[@]}
		echo 'You selected: Main & TSS hub lvl 2 notif servers'
        ;;
	10)
        hostsarray=${ALLUKNOTIF[@]}
                echo 'You selected: All UK4 notif servers'
        ;;
        11)
        hostsarray=${UKL1NOTIF[@]}
                echo 'You selected: UK4 lvl 1 notif servers'
        ;;
        12)
        hostsarray=${UKL2NOTIF[@]}
                echo 'You selected: UK4 lvl 2 notif servers'
        ;;
        13)
        hostsarray=${ALL[@]}
                echo 'You selected: ALL notif servers'
        ;;
	14)
        hostsarray=${SPARE[@]}
                echo 'You selected: SPARE servers'
        ;;
	15)
	hostsarray=${CUTOVERSTEP6[@]}
                echo 'You selected: FR1 MAIN HUB LVL 1, TSS HUB LVL 1 and SPARE SERVERS'
        ;;
	16)
        hostsarray=${MOHOSTS[@]}
                echo 'You selected: mo routers'
        ;;

        x)
        echo "Exiting..."
        exit 0
        ;;
        *)
        echo "That is not a valid choice!"
		echo
        ;;
esac

done
echo
echo ${hostsarray[@]}
echo
echo 'Select command to execute:'
echo
echo '1) custom command'
echo '2) copy using scp'


echo 
echo -n 'Enter your selection: '
read cmdchoice
echo

case $cmdchoice in
		1)
		echo -n 'Enter custom command: '
		read cmd
		cmdtype="ssh"
		;;
		2)
		echo -n 'Enter source file: '
		read sourcefile
		echo -n 'Enter destination file: '
		read destfile
		cmdtype="scp"
		;;
		*)
		echo "WRONG INPUT! Exiting..."
        exit 0
        ;;
esac

echo

if [ $cmdtype == "ssh" ]
then

for i in ${hostsarray[@]}
do 
echo "Executing command in $i ..."
ssh production1@$i "export PATH=\$PATH:/opt/HUB/bin; $cmd"
echo
done

elif  [ $cmdtype == "scp" ]
then

echo "Source file:"
ls -l $sourcefile
echo
for i in ${hostsarray[@]}
do 
echo "Copying file to $i ..."
scp $sourcefile production1@$i:$destfile
ssh production1@$i ls -l $destfile
echo
done
fi
echo
echo "Processing complete."
