#!/bin/bash
##############################################################################
##
## Description  : Script to switch Enterprise Messaging HUB core applications
##                between UK4 DB and FR1 DB
##
## Author       : Sanjan Grero (sanjan.grero@sap.com)
##
##############################################################################



log=/opt/HUB/log/$(basename $0 .sh).log

# List of hosts

# FR1 MT Routers
mtrouters_fr_main=(fr1mtrouter001 fr1mtrouter002 fr1mtrouter003 fr1mtrouter004 fr1mtrouter005 fr1mtrouter006 fr1mtrouter007 fr1mtrouter008)
mtrouters_fr_tss=(fr1mtrouter101 fr1mtrouter102)

# FR1 Notifs
notifs_fr_lvl1_main=(fr1notif001 fr1notif002 fr1notif003 fr1notif004)
notifs_fr_lvl2_main=(fr1notif005 fr1notif006 fr1notif007 fr1notif008 fr1notif009 fr1notif010)
notifs_fr_lvl1_tss=(fr1notif101 fr1notif102)
notifs_fr_lvl2_tss=(fr1notif103 fr1notif104)

# FR1 MO Routers
morouters_fr_main=(fr1morouter001 fr1morouter002)
morouters_fr_tss=(fr1morouter101 fr1morouter102)

# UK4 MT Routers
mtrouters_uk_main=(uk4mtrouter01 uk4mtrouter02 uk4mtrouter003 uk4mtrouter004 uk4mtrouter005 uk4mtrouter006)

# UK4 Notifs
notifs_uk_lvl1_main=(uk4notifa01 uk4notifa02)
notifs_uk_lvl2_main=(uk4notifb01 uk4notifb02)

# UK4 MO Routers
morouters_uk_main=(uk4morouter01 uk4morouter02)

# US2 MT Routers
mtrouters_us_main=(us2appstage006 us2appstage005)

# US2 Notifs
notifs_us_lvl1_main=(us2appstage007)
notifs_us_lvl2_main=(us2appstage001)

# US2 MO Routers
morouters_us_main=(us2appstage010)


# List of configuration files

mtconf="/opt/HUB/MTRouter/conf/mtrouter.properties"
dtwconf="/opt/HUB/dtw_spoolmanager/conf/spoolConfig.xml"
notifl1sockconf="/opt/HUB/etc/sock_mv-notif_lvl1.ini"
notifl2filterconf="/opt/HUB/ixng-a2pjmstools/etc/Notif_Filter.properties"
moconf="/opt/HUB/etc/asepwd.ini"

# Functions for MT Routers

#######################################################################
# Restart Apps in MT Routers
# - JMTRouter
# - dtw_spoolmanager
# - sock_mv client to notif lvl1
# Globals:
#   None
# Arguments:
#   List of servers
#######################################################################

function f_restart_mtrouter_apps {

for host in "$@"
do

echo -e "\n$(date +%F' '%T) ==> Restarting MT applications in [$host]\n" | tee -a "${log}"

ssh -T production1@$host /bin/bash <<EOF | tee -a "${log}"

export PATH=\$PATH:/opt/HUB/bin

echo -e "\n==> Restarting JMTRouter ...\n"
lc restart JMTRouter 2>&1

echo -e "\n==> Restarting dtw_spoolmanager ...\n"
lc restart dtw_spoolmanager 2>&1

echo -e "\n==> Restarting sock mv processes ...\n"
for process in \$(lc status 2>/dev/null | grep "sock.*notif" | awk '{print \$1}');do lc restart \$process;done
for process in \$(lc nok 2>/dev/null | grep "sock.*notif" | awk '{print \$1}');do lc restart \$process;done

EOF

done

}

#######################################################################
# Update configuration in MT Router Apps to connect to UK4 Database
# - JMTRouter
# - dtw_spoolmanager
# - sock_mv client
# Globals:
#   Config file names
#   - JMTRouter - mtrouter.properties
#   - dtw_spoolmanager - SpoolConfig.xml
#   - sock_mv client - sock_mv-notif_lvl1.ini
# Arguments:
#   List of servers
#######################################################################

function f_mtrouter_switch2ukdb {

for host in "$@"
do

echo -e "\n$(date +%F' '%T) ==> Switching MT applications in [$host] to UK4 DB\n" | tee -a "${log}"

ssh -T production1@$host /bin/bash <<EOF | tee -a ${log}

echo -e "\nUpdating JMTrouter and dtw_spoolmanager config in \$(hostname)\n"

if [[ "\$(hostname)" =~ "us2*" ]]
then
sed -i.\$(date +%Y%m%d%H%M%S) 's@us2a2pasedb001.lab:5000/a2p_msgdb_fr1@us2a2pasedb002.lab:5000/a2p_msgdb_uk4@g' $mtconf $dtwconf 2>&1
else
sed -i.\$(date +%Y%m%d%H%M%S) 's@fr1a2pasedbvcs:5000/a2p_msgdb_fr1@uk4a2pasedbvcs:5000/a2p_msgdb_uk4@g' $mtconf $dtwconf 2>&1
fi

echo -e "\nUpdating notif lvl1 sock mv config in \$(hostname)\n"
if [[ "\$(hostname)" =~ "uk4*" ]]
then
sed -i.\$(date +%Y%m%d%H%M%S) 's@updatemtnotif_fr/inputspool@updatemtnotif/inputspool@g' $notifl1sockconf 2>&1
else
sed -i.\$(date +%Y%m%d%H%M%S) 's@updatemtnotif/inputspool@updatemtnotif_uk/inputspool@g' $notifl1sockconf 2>&1
fi

EOF

done

f_restart_mtrouter_apps "$@"

}

#######################################################################
# Update configuration in MT Router Apps to connect to FR1 Database
# - JMTRouter
# - dtw_spoolmanager
# - sock_mv client
# Globals:
#   Config file names
#   - JMTRouter - mtrouter.properties
#   - dtw_spoolmanager - SpoolConfig.xml
#   - sock_mv client - sock_mv-notif_lvl1.ini
# Arguments:
#   List of servers
#######################################################################

function f_mtrouter_switch2frdb {

for host in "$@"
do

echo -e "\n$(date +%F' '%T) ==> Switching MT applications in [$host] to FR1 DB\n" | tee -a "${log}"

ssh -T production1@$host /bin/bash <<EOF | tee -a ${log}

echo -e "\nUpdating JMTrouter and dtw_spoolmanager config in \$(hostname)\n"
if [[ "\$(hostname)" =~ "us2*" ]]
then
sed -i.\$(date +%Y%m%d%H%M%S)  's@us2a2pasedb002.lab:5000/a2p_msgdb_uk4@us2a2pasedb001.lab:5000/a2p_msgdb_fr1@g' $mtconf $dtwconf 2>&1
else
sed -i.\$(date +%Y%m%d%H%M%S) 's@uk4a2pasedbvcs:5000/a2p_msgdb_uk4@fr1a2pasedbvcs:5000/a2p_msgdb_fr1@g' $mtconf $dtwconf 2>&1
fi

echo -e "\nUpdating notif lvl1 sock mv config in \$(hostname)\n"
if [[ "\$(hostname)" =~ "uk4*" ]]
then
sed -i.\$(date +%Y%m%d%H%M%S) 's@updatemtnotif/inputspool@updatemtnotif_fr/inputspool@g' $notifl1sockconf 2>&1
else
sed -i.\$(date +%Y%m%d%H%M%S) 's@updatemtnotif_uk/inputspool@updatemtnotif/inputspool@g' $notifl1sockconf 2>&1
fi

EOF

done

f_restart_mtrouter_apps "$@"

}

# Functions for Notifs

#######################################################################
# Restart Apps in Notif Level 2/3 Servers
# - Notif_Filter
# Globals:
#   None
# Arguments:
#   List of servers
#######################################################################

function f_restart_notif_apps {

for host in "$@"
do

echo -e "\n$(date +%F' '%T) ==> Restarting Notif applications in [$host]\n" | tee -a "${log}"

ssh -T production1@$host /bin/bash <<EOF | tee -a "${log}"

export PATH=\$PATH:/opt/HUB/bin:/opt/HUB/lance

echo -e "\n==> Restarting Notif Filter ...\n"
lc restart Notif_Filter

echo -e "\n==> Restarting Update MT Notif ...\n"
for process in \$(lc status 2>/dev/null | grep updatemtnotif | awk '{print \$1}');do lc restart \$process;done
for process in \$(lc nok 2>/dev/null | grep updatemtnotif | awk '{print \$1}');do lc restart \$process;done

EOF

done

}

#######################################################################
# Update configuration in Notif Level 2/3 Server Notif Filter
# to switch output path to input spool of updatemtnotif processes
# connecting to UK4 Database
# Globals:
#   Config file name of Notif Filter
# Arguments:
#   List of servers
#######################################################################

function f_notiflvl2_switch2ukdb {

for host in "$@"
do

echo -e "\n$(date +%F' '%T) ==> Switching Notif applications in [$host] to UK4 DB\n" | tee -a "${log}"

ssh -T production1@$host /bin/bash <<EOF | tee -a ${log}

echo -e "\nUpdating Notif Filter config in \$(hostname)\n"
if [[ "\$(hostname)" =~ "uk4*" ]]
then
sed -i.\$(date +%Y%m%d%H%M%S) 's@path = /opt/HUB/NOTIF/updatemtnotif_fr\$@path = /opt/HUB/NOTIF/updatemtnotif@g' $notifl2filterconf 2>&1
else
sed -i.\$(date +%Y%m%d%H%M%S) 's@path = /opt/HUB/NOTIF/updatemtnotif\$@path = /opt/HUB/NOTIF/updatemtnotif_uk@g' $notifl2filterconf 2>&1
fi

EOF

done

f_restart_notif_apps "$@"

}

#######################################################################
# Update configuration in Notif Level 2/3 Server Notif Filter
# to switch output path to input spool of updatemtnotif processes
# connecting to FR1 Database
# Globals:
#   Config file name of Notif Filter
# Arguments:
#   List of servers
#######################################################################


function f_notiflvl2_switch2frdb {

for host in "$@"
do

echo -e "\n$(date +%F' '%T) ==> Switching Notif applications in [$host] to FR1 DB\n" | tee -a "${log}"

ssh -T production1@$host /bin/bash <<EOF | tee -a ${log}

echo -e "\nUpdating Notif Filter config in \$(hostname)\n"
if [[ "\$(hostname)" =~ "uk4*" ]]
then
sed -i.\$(date +%Y%m%d%H%M%S) 's@path = /opt/HUB/NOTIF/updatemtnotif\$@path = /opt/HUB/NOTIF/updatemtnotif_fr@g' $notifl2filterconf 2>&1
else
sed -i.\$(date +%Y%m%d%H%M%S) 's@path = /opt/HUB/NOTIF/updatemtnotif_uk\$@path = /opt/HUB/NOTIF/updatemtnotif@g' $notifl2filterconf 2>&1
fi

EOF

done

f_restart_notif_apps "$@"

}

# Functions for MO Routers

#######################################################################
# Restart Apps in MO Routers
# - mosendsmsinterface-XXXXXXXXX
# Globals:
#   None
# Arguments:
#   List of servers
#######################################################################

function f_restart_morouter_apps {

for host in "$@"
do

echo -e "\n$(date +%F' '%T) ==> Restarting MO applications in [$host]\n" | tee -a "${log}"

ssh -T production1@$host /bin/bash <<EOF | tee -a "${log}"

export PATH=\$PATH:/opt/HUB/bin:/opt/HUB/lance

echo -e "\n==> Restarting MO Router ...\n"
for process in \$(lc status 2>/dev/null | grep "mosendsmsinterface" | awk '{print \$1}');do lc restart \$process;done
for process in \$(lc nok 2>/dev/null | grep "mosendsmsinterface" | awk '{print \$1}');do lc restart \$process;done

EOF

done

}

#######################################################################
# Update configuration in MO Routers to connect to UK4 Database
# Globals:
#   Name of ASE password file used by mosendsmsinterface processes
# Arguments:
#   List of servers
#######################################################################

function f_morouter_switch2ukdb {

for host in "$@"
do

echo -e "\n$(date +%F' '%T) ==> Switching MO applications in [$host] to UK4 DB\n" | tee -a "${log}"

ssh -T production1@$host /bin/bash <<EOF | tee -a ${log}

echo -e "\nUpdating MO router config in \$(hostname)\n" 
if [[ "\$(hostname)" =~ "us2*" ]]
then
sed -i.\$(date +%Y%m%d%H%M%S) 's@^HUBMO=DTSA2PFR2\$@HUBMO=DTSA2PUK2@g' $moconf 2>&1
else
sed -i.\$(date +%Y%m%d%H%M%S) 's@^HUBMO=PDSA2PFR5\$@HUBMO=PDSA2PUK9@g' $moconf 2>&1
fi

EOF

done

f_restart_morouter_apps "$@"

}

#######################################################################
# Update configuration in MO Routers to connect to FR1 Database
# Globals:
#   Name of ASE password file used by mosendsmsinterface processes
# Arguments:
#   List of servers
#######################################################################

function f_morouter_switch2frdb {

for host in "$@"
do

echo -e "\n$(date +%F' '%T) ==> Switching MO applications in [$host] to FR1 DB\n" | tee -a "${log}"

ssh -T production1@$host /bin/bash <<EOF | tee -a ${log}

echo -e "\nUpdating MO router config in \$(hostname)\n" 
if [[ "\$(hostname)" =~ "us2*" ]]
then
sed -i.\$(date +%Y%m%d%H%M%S) 's@^HUBMO=DTSA2PUK2\$@HUBMO=DTSA2PFR2@g' $moconf 2>&1
else
sed -i.\$(date +%Y%m%d%H%M%S) 's@^HUBMO=PDSA2PUK9\$@HUBMO=PDSA2PFR5@g' $moconf 2>&1
fi

EOF

done

f_restart_morouter_apps "$@"

}

# Functions for Sub-Menus

#######################################################################
# Show menu options for FR1 HUB
# Separate options for MAIN and TSS HUBs as well as MT/Notif and MO
# Globals:
#   None
# Arguments:
#   None
#######################################################################

function  f_switch_fr_hub {

echo -e "\nYou have selected: FR1 Production HUB\n"

local options=("Set FR1 MAIN HUB MT/NOTIF Apps to UK4 DB" "Set FR1 MAIN HUB MO Apps to UK4 DB" 
			   "Set FR1 MAIN HUB MT/NOTIF Apps to FR1 DB" "Set FR1 MAIN HUB MO Apps to FR1 DB"
			   "Set FR1 TSS HUB MT/NOTIF Apps to UK4 DB" "Set FR1 TSS HUB MO Apps to UK4 DB" 
			   "Set FR1 TSS HUB MT/NOTIF Apps to FR1 DB" "Set FR1 TSS HUB MO Apps to FR1 DB"
			   "Cancel")

select action in "${options[@]}"
do

case $REPLY in

	1)	f_mtrouter_switch2ukdb "${mtrouters_fr_main[@]}"
		f_notiflvl2_switch2ukdb "${notifs_fr_lvl2_main[@]}"
		break ;;
	
	2)	f_morouter_switch2ukdb "${morouters_fr_main[@]}"
		break ;;
	
	
	3)	f_mtrouter_switch2frdb "${mtrouters_fr_main[@]}"
		f_notiflvl2_switch2frdb "${notifs_fr_lvl2_main[@]}"
		break ;;
		
	4)	f_morouter_switch2frdb "${morouters_fr_main[@]}"
		break ;;
		
	5)	f_mtrouter_switch2ukdb "${mtrouters_fr_tss[@]}"
		f_notiflvl2_switch2ukdb "${notifs_fr_lvl2_tss[@]}"
		break ;;
		
	6)	f_morouter_switch2ukdb "${morouters_fr_tss[@]}"
		break ;;
	
	7)	f_mtrouter_switch2frdb "${mtrouters_fr_tss[@]}"
		f_notiflvl2_switch2frdb "${notifs_fr_lvl2_tss[@]}"
		break ;;
		
	8)	f_morouter_switch2frdb "${morouters_fr_tss[@]}"
		break ;;
		
	9)	echo -e "\nOperation Cancelled.\n"
		show_main_menu
		break ;;
	
	*) 	echo -e "\nInvalid Option - Try Again!\n"
		;;
	
esac

done

}

#######################################################################
# Show menu options for UK4 HUB
# Separate options for MT/Notif and MO
# Globals:
#   None
# Arguments:
#   None
#######################################################################

function  f_switch_uk_hub {

echo -e "\nYou have selected: UK4 Production HUB\n"

local options=("Set UK4 HUB MT/NOTIF Apps to UK4 DB" "Set UK4 HUB MO Apps to UK4 DB" 
			   "Set UK4 HUB MT/NOTIF Apps to FR1 DB" "Set UK4 HUB MO Apps to FR1 DB"
			   "Cancel")

select action in "${options[@]}"
do

case $REPLY in

	1)	f_mtrouter_switch2ukdb "${mtrouters_uk_main[@]}"
		f_notiflvl2_switch2ukdb "${notifs_uk_lvl2_main[@]}"
		break ;;
	
	2)	f_morouter_switch2ukdb "${morouters_uk_main[@]}"
		break ;;
		
	3)	f_mtrouter_switch2frdb "${mtrouters_uk_main[@]}"
		f_notiflvl2_switch2frdb "${notifs_uk_lvl2_main[@]}"
		break ;;

	4)	f_morouter_switch2frdb "${morouters_uk_main[@]}"
		break ;;
		
	5)	echo -e "\nOperation Cancelled.\n"
		show_main_menu
		break ;;
		
	*) 	echo -e "\nInvalid Option - Try Again!\n"
		;;
		
esac

done

}

#######################################################################
# Show menu options for US2 Staging HUB
# Separate options for MT/Notif and MO
# Globals:
#   None
# Arguments:
#   None
#######################################################################

function  f_switch_us_hub {

echo -e "\nYou have selected: US2 Staging HUB\n"

local options=("Set US2 Staging MT/NOTIF Apps to UK4 DB" "Set US2 Staging MO Apps to UK4 DB" 
			   "Set US2 Staging MT/NOTIF Apps to FR1 DB" "Set US2 Staging MO Apps to FR1 DB" 
			   "Cancel")

select action in "${options[@]}"
do

case $REPLY in

	1)	f_mtrouter_switch2ukdb "${mtrouters_us_main[@]}"
		f_notiflvl2_switch2ukdb "${notifs_us_lvl2_main[@]}"
		break ;;
	
	2)	f_morouter_switch2ukdb "${morouters_us_main[@]}"
		break ;;
		
	3)	f_mtrouter_switch2frdb "${mtrouters_us_main[@]}"
		f_notiflvl2_switch2frdb "${notifs_us_lvl2_main[@]}"
		break ;;

	4)	f_morouter_switch2frdb "${morouters_us_main[@]}"
		break ;;
		
	5)	echo -e "\nOperation Cancelled.\n"
		show_main_menu
		break ;;
	
	*) 	echo -e "\nInvalid Option - Try Again!\n"
		;;

esac

done

}

#######################################################################
# Show menu options for selection of messaging HUB
# Globals:
#   None
# Arguments:
#   None
#######################################################################

function show_main_menu {

clear
export COLUMNS=1

echo -e "\n===================================="
echo -e "| Switch DB Script ( FR1 <-> UK4 ) |"
echo -e "====================================\n"

msghubs=("Select FR1 HUB" "Select UK4 HUB" "Select US2 Staging HUB" "Exit")

PS3="Select Action: "

select hub in "${msghubs[@]}"
do
case $hub in
	
	"Select FR1 HUB") f_switch_fr_hub
	break ;;	
	
	"Select UK4 HUB") f_switch_uk_hub
	break ;;

	"Select US2 Staging HUB") f_switch_us_hub
	break ;;
	
	"Exit") echo -e "\nGoodbye!\n"
	break ;;
	
	*) echo -e "\nInvalid Option - Try Again!\n"
	;;

esac

done

}

# Execute the main menu
echo -e "\n$(date +%F' '%T) ==> START execution of script by $(whoami) \n" | tee -a "${log}"
show_main_menu;