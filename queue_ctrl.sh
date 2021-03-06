#!/bin/bash

log=/opt/HUB/log/$(basename $0 .sh).log
localrouter=$1
port=$2
backuprouter1=$3
backuprouter2=$4
clifile=/opt/HUB/tmp/$(basename $0 .sh)_smq_cmd.cli
cliscript=/opt/HUB/tmp/$(basename $0 .sh)_bash_cmd.sh
touch ${cliscript}
chmod 700 ${cliscript}

batchsize=10000
maxcount=50000
regexnum="[[:digit:]]+"
clicode="java -cp /opt/HUB/swiftmq/jars/swiftmq.jar:/opt/HUB/swiftmq/jars/jline.jar:/opt/HUB/swiftmq/jars/jndi.jar:/opt/HUB/swiftmq/jars/jms.jar:/opt/HUB/swiftmq/jars/dom4j-full.jar:/opt/HUB/swiftmq/jars/xstream.jar -Dcli.username=admin -Dcli.password=secret com.swiftmq.admin.cli.CLI smqp://localhost:${port} plainsocket@${localrouter} ${clifile}"
srcrouter=""
srcqueue=""
destrouter=""
destqueue=""
customerid=-1

function cleanup {
  rm -f ${clifile} ${cliscript}
  return $?
}
 
function control_c {
  display "*** Ouch! Exiting ***"
  cleanup
  exit $?
}
 
# trap keyboard interrupt (control-c)
trap control_c SIGINT

function moveit {

local resume=$1


#Source router stuff

if [[ ${resume} -eq 0 ]];then
read -p "Enter production router name: " srcrouter
else
srcrouter=$(whiptail --title "Select Backup Router" --noitem \
--radiolist "Press:\n<SPACE> to select/de-select\n<UP/DOWN> to scroll through items\n<TAB> to navigate components" 20 80 10 \
${backuprouter1} on \
${backuprouter2} off \
3>&1 1>&2 2>&3)

display "Selected backup router: ${srcrouter}"

fi

display "Checking availability of source router: ${srcrouter}"
echo "( press Ctrl+C if program stops responding for over 10 seconds... )"

echo "${clicode} | grep \"^${srcrouter}$\"" > ${cliscript}

echo "wr ${srcrouter}
ar
exit"| tee -a ${log} > ${clifile}

srcrouteravailable=$( cmdpid=${BASHPID}; (sleep 3; pkill -P ${cmdpid} java 2>/dev/null) &  ${cliscript})

if [[ "${srcrouteravailable}" == "${srcrouter}" && "${srcrouter}" != "" ]];then
  #display "Source router: ${srcrouter} is available for processing."
  if [[ ${resume} -eq 1 ]];then
  listqueues
  fi
else
  display "Router: ${srcrouter} is not available. exiting..."
  exit 1
fi


#Source queue stuff
echo
if [[ ${resume} -eq 0 ]];then
read -p "Enter production queue name: " srcqueue
else
read -p "Enter backup queue name: " srcqueue
fi

#display "Checking availability of source queue: ${srcqueue}"

echo "${clicode} | grep -c \"^Entity:.*Queue$\"" > ${cliscript}

echo "wr ${srcrouter}
sr ${srcrouter}
lc sys\$queuemanager/queues/${srcqueue}
exit"| tee -a ${log} > ${clifile}

srcqueueavailable=$(${cliscript})

if ! [[ ${srcqueueavailable} -eq 1 && "${srcqueue}" != ""  ]];then
  display "Queue: ${srcqueue}@${srcrouter} is not available. exiting..."
  exit 1
fi


#Destination router stuff

if [[ ${resume} -eq 1 ]];then
echo
read -p "Enter production router name: " destrouter
else
destrouter=$(whiptail --title "Select Backup Router" --noitem \
--radiolist "Press:\n<SPACE> to select/de-select\n<UP/DOWN> to scroll through items\n<TAB> to navigate components" 20 80 10 \
${backuprouter1} on \
${backuprouter2} off \
3>&1 1>&2 2>&3)

display "Selected backup router: ${destrouter}"

fi

display "Checking availability of router: ${destrouter}"
echo "( press Ctrl+C if program stops responding for over 10 seconds... )"

echo "${clicode} | grep \"^${destrouter}$\"" > ${cliscript}

echo "wr ${destrouter}
ar
exit"| tee -a ${log} > ${clifile}

destrouteravailable=$( cmdpid=${BASHPID}; (sleep 3; pkill -P ${cmdpid} java 2>/dev/null) &  ${cliscript})

if ! [[ "${destrouteravailable}" == "${destrouter}"  && "${destrouter}" != ""   ]];then
  display "Router: ${destrouter} is not available. exiting..."
  exit 1
fi

#Destination Queue Stuff

if [[ ${resume} -eq 1 ]];then
  echo
  read -p "Enter production queue name: " destqueue

  #display "Checking availability of destination queue: ${destqueue}"

  echo "${clicode} | grep -c \"^Entity:.*Queue$\"" > ${cliscript}

  echo "wr ${destrouter}
  sr ${destrouter}
  lc sys\$queuemanager/queues/${destqueue}
  exit"| tee -a ${log} > ${clifile}

  destqueueavailable=$(${cliscript})

  if ! [[ ${destqueueavailable} -eq 1  && "${destqueue}" != ""   ]];then
    display "Production queue: ${destqueue} is not available. exiting..."
    exit 1
  fi

else
  destqueue="SR_${srcqueue}_${srcrouter}_"
fi

#Customer ID stuff
echo
read -p "Select messages by Customer Id? (yes/no): " filterbycustomer



if [[ "${filterbycustomer}" == "yes" ]];then
read -p "Enter Customer Id: " customerid
fi

if [[ ${resume} -eq 0 ]];then
  if [[ ${customerid} -ne -1 ]];then
  destqueue+=${customerid}
  else
  destqueue+=ALLCUST
  fi
  destqueue+=_$(date +%Y%m%d%H%M%S)
fi


#Check source queue depth

#display "Checking source queue depth ..."

echo "${clicode} | grep \"^messagecount\" | awk '{print \$3}'" > ${cliscript}

echo "wr ${srcrouter}
sr ${srcrouter}
lc sys\$queuemanager/usage/${srcqueue}
exit"| tee -a ${log} > ${clifile}

srcqueuedepth=$(${cliscript})

if [[ ${srcqueuedepth} -eq 0 ]];then
display "${srcqueue}@${srcrouter} is empty! Exiting..."
exit 0
elif [[ ${srcqueuedepth} -gt ${maxcount} && ${resume} -eq 0 && ${customerid} -eq -1 ]];then
display "Production queue depth: ${srcqueuedepth} exceeds the maximum count: ${maxcount}"
echo
read -p "Enter a sequence number for this move: " seqnum
if [[ ${seqnum} =~ ${regexnum} ]];then
destqueue+=_$( printf "%03d" ${seqnum} )
else
display "Entered value is not a number! Exiting ..."
exit 1
fi

fi

summary #print the summary
echo
read -p "Proceed with moving messages? (yes/no): " proceedconfirmation

if [[ "${proceedconfirmation}" != "yes" ]];then
  display "Operation cancelled. exiting..."
  exit 1
fi

if [[ ${resume} -eq 0 ]];then

display "Creating backup queue: ${destqueue}"

echo "${clicode}" > ${cliscript}

echo "wr ${destrouter}
sr ${destrouter}
cc sys\$queuemanager/queues
new ${destqueue} persistence-mode persistent flowcontrol-start-queuesize -1
save
exit"| tee -a ${log} > ${clifile}

${cliscript} > /dev/null 2>&1

echo "${clicode} | grep -c \"^Entity:.*Queue$\"" > ${cliscript}

echo "wr ${destrouter}
sr ${destrouter}
lc sys\$queuemanager/queues/${destqueue}
exit"| tee -a ${log} > ${clifile}


destqueueavailable=$(${cliscript})

if ! [[ ${destqueueavailable} -eq 1 ]];then
  display "Queue: ${destqueue} in ${destrouter} could not be created. exiting..."
  exit 1
fi

fi

display "Preparing to move messages ..."

#echo "${clicode} | grep \"^[0-9]+ messages processed\"" > ${cliscript}
echo "${clicode} | grep -v administration | grep -v Waiting " > ${cliscript}

if [[ ${customerid} -ne -1 ]];then

display "Moving customer:${customerid} from:${srcqueue}@${srcrouter} to ${destqueue}@${destrouter}"

echo "wr ${srcrouter}
sr ${srcrouter}
cc sys\$queuemanager/usage
move ${srcqueue} -queue ${destqueue}@${destrouter} -selector MAILORDER_CustomerId='${customerid}'
exit"| tee -a ${log} > ${clifile}

result=$(${cliscript})
display "${result}"

else

local loop=1

if [[ ${srcqueuedepth} -ge ${maxcount} ]];then
loop=$(( ( ${maxcount} / ${batchsize})  ))
elif [[ ${srcqueuedepth} -lt ${maxcount} && ${srcqueuedepth} -gt ${batchsize} ]];then
loop=$(( (${srcqueuedepth} / ${batchsize}) + 1 ))
fi


display "Moving ALL CUSTOMER's messages in ${loop} batch(es)"

echo "wr ${srcrouter}
sr ${srcrouter}
cc sys\$queuemanager/usage
move ${srcqueue} -queue ${destqueue}@${destrouter} -index 0 $((${batchsize} - 1))
exit"| tee -a ${log} > ${clifile}

for (( count=1; count<=${loop}; count++ ))
do
display "Moving batch ${count}: from:${srcqueue}@${srcrouter} to ${destqueue}@${destrouter}"
result=$(${cliscript})
display "Completed moving batch ${count}. ${result}"
sleep 5
done

fi

if [[ ${resume} -eq 1 ]];then

display "Executing clean up tasks ..."

echo "${clicode} | grep \"^messagecount\" | awk '{print \$3}'" > ${cliscript}

echo "wr ${srcrouter}
sr ${srcrouter}
lc sys\$queuemanager/usage/${srcqueue}
exit"| tee -a ${log} > ${clifile}

srcqueuedepth=$(${cliscript})

display "Unable to remove ${srcqueue}@${srcrouter} . There are ${srcqueuedepth} message(s) left in the queue."

if [[ ${srcqueuedepth} -eq 0 ]];then

display "Removing empty queue: ${srcqueue} from router: ${srcrouter}"

echo "${clicode}" > ${cliscript}

echo "wr ${srcrouter}
sr ${srcrouter}
cc sys\$queuemanager/queues
delete ${srcqueue}
save
exit"| tee -a ${log} > ${clifile}

${cliscript} > /dev/null 2>&1

display "Completed removing queue: ${srcqueue} from router: ${srcrouter}"

fi
fi

echo

display "==> COMPLETED queue moving process"

showmenu

}

function showmenu {

export COLUMNS=1

options=("Move to Backup Queue"
         "Move to Production Queue"
         "Display Queue Depth"
         "Exit")

PS3="Select Option: "

select action in "${options[@]}"
do
case ${REPLY} in

        1)      display "==> Move to backup queue\n"
				moveit 0
                break ;;

        2)      display "==> Move to production queue\n"
				moveit 1
                break ;;

        3)      queuedepth
				break ;;

		4)      echo ""
                exit 0
                break ;;

        *)      echo -e "\nInvalid Option - Try Again!\n"
                ;;
esac
done

}
function queuedepth {
local router
local byqueue
local queue
read -p "Enter router name: " router
read -p "Check specific queue? (yes/no): " byqueue

if [[ "${byqueue}" == "yes" ]];then
read -p "Enter queue name: " queue
/opt/HUB/scripts/queue_depth.pl -r ${localrouter} -p ${port} -c ${router} -q ${queue}
else
/opt/HUB/scripts/queue_depth.pl -r ${localrouter} -p ${port} -c ${router}
fi
echo
showmenu

}


function showusage {
echo -e "\nQueue Control Script: v1.4"
echo -e "\nUsage: $0 [local router name] [local router port] [backup router 1] [backup router 2]"
echo -e "Eg: $0 mylocalrouter 1234\n"
exit 1
}

function display {

local string=$1
echo -e "\n${string}"
echo -e "\n$(date +%F' '%T) ${string}" >> ${log}

}

function listqueues {

display "Checking backup queues in: ${srcrouter}"

echo "${clicode} | grep \"^SR\"" > ${cliscript}

echo "wr ${srcrouter}
sr ${srcrouter}
lc sys\$queuemanager/usage/
exit" | tee -a ${log} > ${clifile}

local queuelist=( $(${cliscript}) )

if [ ${#queuelist[@]} -ne 0 ]; then
display "List of backup queues in: ${srcrouter}"
printf "%s\n" "${queuelist[@]}" | tee -a ${log}
fi

echo
}

function summary {

cat <<EOF

Summary of Parameters
=====================================
From: ${srcqueue}@${srcrouter} (currently has ${srcqueuedepth} messages)
To: ${destqueue}@${destrouter}
EOF

if [[ ${customerid} -ne -1 ]];then
  echo -e "Customer ID(s) to be moved: CustomerID ${customerid} only"
  echo -e "Total messages to be moved: All messages with CustomerID=${customerid}"
  echo -e "Note: Messages will be moved in ONE batch"
else
  echo -e "Customer ID(s) to be moved: All CustomerIDs"
  if [[ ${srcqueuedepth} -gt ${maxcount} ]];then
  echo -e "Total no. of messages to be moved: ${maxcount}  ( run again to move the rest of the messages )"
  else
  echo "Total no. of messages to be moved: ${srcqueuedepth}"
  fi
  echo -e "No. of messages per batch: ${batchsize}"
fi

}

function showstart {

display "==> START of script"
clear
cat <<EOF

======================================================
==================== Queue Control ===================
======================================================

Notes: When moving from production to backup the backup
       queue will be created by the script automatically
	   
EOF

showmenu
}



if [[ $# -lt 4 ]];then
showusage
else
showstart
fi
