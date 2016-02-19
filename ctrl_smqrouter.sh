#!/bin/bash

function showusage {
echo
echo "Usage: $0 [router name] [start/stop] [max heap (optional for start): 2GB/3GB/4GB]"
echo "Eg: start w/ 2GB max heap (default): $0 my_smq_router start"
echo "Eg: start w/ 4GB max heap: $0 my_smq_router start 4GB"
echo
exit 1
}

if [[ $# -lt 2 ]];then
showusage
fi

#echo
#echo -n "Are you in the correct SwiftMQ version's directory?  (Y/N): "
#read choice
#if [ "$choice" != "Y" ]
#then
#echo "Please change dir to the correct SwiftMQ version's /scripts/unix/ directory."
#echo
#exit 1
#fi

echo

ROUTER=$1
LOG=/opt/HUB/log/${ROUTER}_console.log
DATE=`date "+%F %T"`
MEM="-Xms2G -Xmx2G"
PID=`ps -efww | grep $ROUTER/routerconfig.xml | grep -v grep | awk '{print $2}'`
PORT=`grep connectaddress ../../config/$ROUTER/routerconfig.xml | sed "s/.*port=\"\(.*\)\".*/\1/"`

if [[ -n "$3" ]]; then
if [[ "$3" == "1GB" ]]; then
MEM="-Xms1G -Xmx1G"
elif [[ "$3" == "2GB" ]]; then
MEM="-Xms2G -Xmx2G"
elif [[ "$3" == "3GB" ]]; then
MEM="-Xms3G -Xmx3G"
elif [[ "$3" == "4GB" ]]; then
MEM="-Xms4G -Xmx4G"
fi
fi


echo
case "$2" in
'start')

        if [ -n "$PID" ]; then
        echo -e "\n $(date +%F' '%T)  $ROUTER  is already running! \n" | tee -a $LOG
        exit 1
        fi

        echo "---------------------------------------------------------------------------------------------------"  | tee -a $LOG
        echo "$(date +%F' '%T) Starting SwiftMQ Router: $ROUTER , Heap Size: $MEM"  | tee -a $LOG
        echo "Log File : $LOG"
        echo "---------------------------------------------------------------------------------------------------"  | tee -a $LOG


        nohup java -server $MEM -cp ../../jars/swiftmq.jar:../../jars/jndi.jar:../../jars/jms.jar:../../jars/dom4j-full.jar:../../jars/xstream.jar com.swiftmq.Router ../../config/$ROUTER/routerconfig.xml >> $LOG 2>&1 &

        PID=$!
        echo "$(date +%F' '%T) SwiftMQ Router: $ROUTER , Starting with pid: $PID "  | tee -a $LOG
        tail -n 0 -f $LOG | while read logline
        do
        echo ${logline}
        [[ "${logline}" == *"Production is ready"* ]] && pkill -P $$ tail
        done
        echo "$(date +%F' '%T) Starting SwiftMQ Router: $ROUTER completed!"
        ;;

'stop')

        if [ -n "$PID" ]; then
        echo "---------------------------------------------------------------------------------------------------"  | tee -a $LOG
        echo "$(date +%F' '%T) Shutting down SwiftMQ Router: $ROUTER with pid: $PID ..." | tee -a $LOG
        echo "---------------------------------------------------------------------------------------------------"  | tee -a $LOG
        echo "$(date +%F' '%T) Current status of Router: $ROUTER" | tee -a $LOG
        echo "$(date +%F' '%T) PID   %CPU %MEM   RSZ CMD" | tee -a $LOG
        echo "$(date +%F' '%T) "`ps -C java  -o pid,pcpu,pmem,rsz,cmd -ww | grep $ROUTER/routerconfig.xml` | tee -a $LOG
        sync
        echo "wr $ROUTER
        sr $ROUTER
        halt
        exit" > /opt/HUB/tmp/shutdownrouter.cli
        java -cp ../../jars/swiftmq.jar:../../jars/jline.jar:../../jars/jndi.jar:../../jars/jms.jar:../../jars/dom4j-full.jar:../../jars/xstream.jar -Dcli.username=admin -Dcli.password=secret com.swiftmq.admin.cli.CLI smqp://`hostname`:$PORT plainsocket@$ROUTER /opt/HUB/tmp/shutdownrouter.cli
        sleep 10
        tail -n 0 -f $LOG | while read logline
        do
        echo ${logline}
        [[ "${logline}" == *"Production DONE"* ]] && pkill -P $$ tail
        done
        echo "$(date +%F' '%T) Waiting for connected TCP sessions to close ..." | tee -a $LOG
        while true;
        do
        sleep 1
        if [[ `netstat -an | grep :$PORT | wc -l` -eq 0 ]]
        then
        echo "$(date +%F' '%T) TCP sessions are closed." | tee -a $LOG
        break
        fi
        done
        echo "$(date +%F' '%T) Shutdown complete for SwiftMQ  Router: $ROUTER with pid: $PID"  | tee -a $LOG
        else
        echo "$(date +%F' '%T) Cannot shutdown SwiftMQ router. Router: $ROUTER not found."  | tee -a $LOG
        fi
        ;;

*)
        showusage
        ;;
esac
echo
