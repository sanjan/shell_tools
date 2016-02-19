#!/bin/sh

export USERID=`id|grep production1|wc -l`
tx_running=`ps -ef | grep nilcom_tss_broker_tx | grep -v grep | wc -l`
rx_running=`ps -ef | grep nilcom_tss_broker_rx | grep -v grep | wc -l`

exitthis () {
				echo 'Exiting without starting connection...'
                echo
                exit 111
}

if [ $USERID = 0 ]
   then
        clear
        echo 'WARNING: Invalid user!'
        echo '======================'
        echo 'User production1 is required to run this process.'
        echo 'Change user to production1 and try again.'
        echo
        echo
        echo 'Current user credentials'
        id
        echo
        echo
        exitthis
fi

if [ $tx_running -gt 0 ]
    then
        echo
        echo "WARNING: found $tx_running processes running for Nilcom_TSS_IXNG_TX"
        ps -ef | grep nilcom_tss_broker_tx | grep -v grep
        echo
        exitthis

fi

if [ $rx_running -gt 0 ]
    then
        echo        
        echo "WARNING: found $rx_running processes running for Nilcom_TSS_IXNG_RX"
        ps -ef | grep nilcom_tss_broker_rx | grep -v grep
        echo
        exitthis
fi

export LD_ASSUME_KERNEL=""
export LD_LIBRARY_PATH=""

#cd /opt/ixng; ./scripts/brokerctrl /opt/ixng/conf/nilcom_tss_broker.xml start
cd /opt/ixng; ./scripts/brokerctrl /opt/ixng/conf/nilcom_tss_broker_tx.xml start
cd /opt/ixng; ./scripts/brokerctrl /opt/ixng/conf/nilcom_tss_broker_rx.xml start