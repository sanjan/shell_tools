#!/bin/sh

DATE=`date`

#manage lock

lock="/tmp/movecomplete_script.lock"

if [ -e $lock ];then
        pid=`cat $lock`
        pid_test=`ps -ef | grep $pid | grep -v grep | cut -f2`
        if [ "$pid" == "$pid_test" ];then
                echo "$DATE : ******************* WARNING *******************"
                echo "$DATE : Previous instance is still running"
                echo "$DATE : ***********************************************"
                exit 1
        else
                rm -f $lock
        fi
fi

echo $$ > $lock

#start script

echo "$DATE : INFO  : Scanning Start ..."

cd /opt/AutomatorFTP

for dir in `ls -1p | grep /\$ | cut -d/ -f1`

do

        if [ -d /opt/jail/$dir/home/$dir ]

        then

                #echo "$DATE : INFO  : Scanning /opt/jail/$dir/home/$dir for new uploads ..."

                cd /opt/jail/$dir/home/$dir

                for file in `ls --ignore=*.log -1p | grep -v /\$`

                do

                        CHECK=`lsof $file | wc -l`

                        echo "$DATE : INFO  : Checking /opt/jail/$dir/home/$dir/$file"

                        if [ $CHECK -eq 0 ]

                        then

                                echo "$DATE : INFO  : Found completed file. Moving ..."

                               mv -fv $file /opt/AutomatorFTP/$dir/$file

                        fi

                done

                #echo "$DATE : INFO  : Scanning /opt/AutomatorFTP/$dir for new logs ..."

                cp -fvu /opt/AutomatorFTP/$dir/*.log /opt/jail/$dir/home/$dir/

        elif [ -d /opt/jail/$dir ]

        then

                #echo "$DATE : INFO  : Scanning /opt/jail/$dir for new uploads ..."

                cd /opt/jail/$dir

                for file in `ls --ignore=*.log -1p | grep -v /\$`

                do

                        CHECK=`lsof $file | wc -l`

                        echo "$DATE : INFO  : Checking /opt/jail/$dir/$file"

                        if [ $CHECK -eq 0 ]

                        then

                                echo "$DATE : INFO  : Found completed file. Moving ..."

                                mv -fv $file /opt/AutomatorFTP/$dir/$file

                        fi

                done

                #echo "$DATE : INFO  : Scanning /opt/AutomatorFTP/$dir for new logs ..."

                cp -fvu /opt/AutomatorFTP/$dir/*.log /opt/jail/$dir/

        fi

done

echo "$DATE : INFO  : Scanning Completed"

rm $lock
