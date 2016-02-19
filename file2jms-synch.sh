#!/bin/sh

process=$1
file=$2
filename=
basefilename="/opt/HUB/etc"
destbasefilename="/opt/HUB/ixng-a2pjmstools-1.3.0-b1/etc"
logfilename="/opt/HUB/log/$0.log"

function help
{
	echo "Usage : $0 <process name> <config file name>"
	echo "Example: $0 file2jms-queue file2jms-queue.properties"
	exit 0
}

function input_filename
{
	local parent=$1

	read -r -p "Enter file name or type \"q\" to quit : " filename
	local filename=${filename}

	case $filename in
	"q" )
	exit 0
	;;
	"Q" )
	exit 0
	;;
	"" )
	input_filename ${parent}
	;;
	*)
	$parent ${filename}
	;;
	esac
}

function file2jms_menu
{
	local filename=$1


	#checking for file existence
	if [[ ! -f ${basefilename}/${filename} ]]
	then
	echo "File ${filename} does not exist"
	input_filename "file2jms_menu"
	else
	#if file exist
	read -r -p "This will synch $filename to ALL MTRouters, and restart $process . continue? [Y/N]: " userinput
	local userinput=${userinput}

	case $userinput in
	"Y" )
	synch_file2jms $filename
	;;
	"N")
	exit 0
	;;
	*)
	file2jms_menu $filename
	;;
	esac
	fi
}

function synch_file2jms
{
	local filename=$1
	local mtrouters="fr1mtrouter001 fr1mtrouter002 fr1mtrouter003 fr1mtrouter004 fr1mtrouter005 fr1mtrouter006 fr1mtrouter007 fr1mtrouter008 fr1mtrouter009 fr1mtrouter010 fr1mtrouter011 fr1mtrouter012 fr1mtrouter013 fr1mtrouter014 fr1mtrouter101 fr1mtrouter102 uk4mtrouter01 uk4mtrouter02 uk4mtrouter003"

	echo "`date +%F' '%T` START Synching ${basefilename}/${filename} " | tee -a ${logfilename}

	for mtrouter in ${mtrouters}
	do
	echo  | tee -a ${logfilename}
	
	echo "`date +%F' '%T` ==> Processing Router: $mtrouter"  | tee -a ${logfilename}

	#Back up original file at remote server
	ssh $mtrouter "[[ -f ${destbasefilename}/${filename} ]] && /bin/cp -v ${destbasefilename}/${filename} ${destbasefilename}/${filename}.`date +%Y%m%d%H%M%S`" 2>&1 | tee -a ${logfilename}

	#Copying file to remote server
	echo "`date +%F' '%T` scp ${basefilename}/${filename} production1@$mtrouter:${destbasefilename}/${filename}" >> ${logfilename}
	scp ${basefilename}/${filename} $mtrouter:${destbasefilename}/${filename} 2>&1 | tee -a ${logfilename}

	#restart file2jms-mtrouter process on remote server

	echo "`date +%F' '%T` stopping process: ${process} in ${mtrouter} ....." | tee -a ${logfilename}

	ssh $mtrouter "export PATH=\$PATH:/opt/HUB/bin:/opt/HUB/lance:/opt/mobileway/bin;lc stop ${process}"  2>&1 | tee -a ${logfilename}
	sleep 5
	
	echo "`date +%F' '%T` scanning for lock files in ${mtrouter} ....."  | tee -a ${logfilename}
	ssh $mtrouter "find /opt/HUB/router/outputspool_real/ -type f -name .lock; echo \"removing lock files\";find /opt/HUB/router/outputspool_real/ -type f -name .lock | xargs rm -vf"  2>&1 | tee -a ${logfilename}
	echo "`date +%F' '%T` scanning and removing lock files in ${mtrouter} is complete." | tee -a ${logfilename}

	echo "`date +%F' '%T` restarting process: ${process} in ${mtrouter} " | tee -a ${logfilename}
	ssh $mtrouter "export PATH=\$PATH:/opt/HUB/bin:/opt/HUB/lance:/opt/mobileway/bin; lc restart ${process}; sleep 2; tail /opt/HUB/log/${process}.log" 2>&1 | tee -a ${logfilename}
	
	done
	
	echo "`date +%F' '%T` END Synching ${basefilename}/${filename} " | tee -a ${logfilename}

	echo | tee -a ${logfilename}

	echo "`date +%F' '%T` Scanning and removing lock files AGAIN! " | tee -a ${logfilename}
	for mtrouter in ${mtrouters}
	do
	echo "`date +%F' '%T` ==> Processing Router: $mtrouter"  | tee -a ${logfilename}
	ssh $mtrouter "echo \"searching for lock files...\"; find /opt/HUB/router/outputspool_real/ -type f -name .lock; echo \"removing lock files\";find /opt/HUB/router/outputspool_real/ -type f -name .lock | xargs rm -vf"  2>&1 | tee -a ${logfilename}
	echo  | tee -a ${logfilename}
	done
	echo "`date +%F' '%T` Completed scanning and removing lock files " | tee -a ${logfilename}

}

case $process in
"file2jms-mtrouter" )
file2jms_menu $file
;;
"file2jms-queue" )
file2jms_menu $file
;;
"file2jms-queue-uk4" )
file2jms_menu $file
;;

*)
help
;;
esac
