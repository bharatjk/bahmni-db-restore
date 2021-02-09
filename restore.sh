#!/bin/bash
#Script to restore mysql backup and write output to status file
#

#TZ is set via Docker run by copying host timezone file.Set below TZ to over ride.
#export TZ=Asia/Kolkata
[ -f  /etc/timezone ] && export TZ=`cat /etc/timezone`
BASEDIR=/data
SRC_BACKUPDIR=${BASEDIR}/backup
DB=$1
Outfile=${BASEDIR}/${DB}-Restore_status.txt
Restorelog=${BASEDIR}/${DB}-Restore.log
thisWeek=$((($(date +%-d)-1)/7+1))

if  [ $# -lt 1 ] ; then
    echo "Usage: restore [ mysql | pg ]"
    exit 1
fi



function CheckExit ()
{
     if [ $? != 0 ] ;then
	 
		echo "FAILED: $MSG" >>$Restorelog
		echo "Failed,`date +%D,%T`,$Client,$backuprootFolder,Failed Task: $MSG " >>$Outfile
		cd ..
		continue
     fi
}

function LogExit0 ()
{
	if [ $? = 0 ] ;then 
	    echo "Success,`date +%D,%T`,$Client,$backuprootFolder,$BackupTarFile,$BackupInfoTxtFile" >>$Outfile 
	     rm -f $Restorelog
	else
	    echo "Failed,`date +%D,%T`,$Client,$backuprootFolder,$BackupTarFile,$BackupInfoTxtFile" >>$Outfile
	fi
}

function doRestore ()
{

	OPTIONS=$1
	   # Restore  task
	   echo "bahmni -i local restore --restore_type=db --options=${OPTIONS} --strategy=pitr --restore_point=$backuprootFolder "
	   bahmni -i local restore --restore_type=db --options=${OPTIONS} --strategy=pitr --restore_point=$backuprootFolder 2>&1 >>$Restorelog

}

function mysqlRestore ()
{ 

BackupTarFile=${Prefix}${thisWeek}.tar.gz
BackupInfoTxtFile=${Prefix}_backup_info${thisWeek}.txt

cd $SRC_BACKUPDIR

for Client in `ls -l|grep ^d|awk '{print $NF}'`
   do
       cd $Client
	   
	   MSG="Check input tar files"
		[  -f  $BackupTarFile ] 
		CheckExit
		
		#Extract bckup to /data/openmrs
		   tar xf $BackupTarFile -C /
		   MSG="Get backuprootFolder name"
		   backuprootFolder=`ls /data/openmrs/`
		   CheckExit
		   
		 MSG="Check input backup info files"  
		 [  -f  $BackupInfoTxtFile ] 
		 CheckExit
		 
		 MSG="Copy BackupInfoTxtFile"
		cp $BackupInfoTxtFile  /data/openmrs/backup_info.txt
		CheckExit
		
           # Call doRestore Function
		   MSG="doRestore"
		   doRestore openmrs
		   CheckExit
		   
		   #Check Restore status
		   MSG="Check Final Restore status"
		   mysql -B -u root -pP@ssw0rd openmrs -e "select * from location;"
		   LogExit0
		   
		   cd ..
		   [ -d /data/openmrs/${backuprootFolder} ] && rm -rf /data/openmrs/$backuprootFolder
		   [ -f /data/openmrs/backup_info.txt ] && rm -f /data/openmrs/backup_info.txt
done
}


function pgRestore ()
{

RESTORE_BASE=/var/lib/pgbackrest/
[ ! -d /var/log/backrest/  ] && mkdir /var/log/backrest/ 
cd $SRC_BACKUPDIR

BackupTarFile=${Prefix}${thisWeek}.tar.gz
BackupInfoTxtFile=${Prefix}backup_info${thisWeek}.txt
BackupInfoFile=${Prefix}bfbackup.info${thisWeek}

for Client in `ls -l|grep ^d|awk '{print $NF}'`
   do
       cd $Client
	   MSG="Check input backup files"
    	[  -f  $BackupTarFile -a  -f  $BackupInfoTxtFile -a  -f  $BackupInfoFile ] 
	    CheckExit

		#Extract bckup to /var/lib/pgbackrest/
		tar xf $BackupTarFile -C /
		MSG="Get backuprootFolder name"
		backuprootFolder=`ls  -d ${RESTORE_BASE}/backup/bahmni-postgres/2*|awk -F/ '{print $NF}'`
		CheckExit

		MSG="Copy BackupInfoTxtFile"
		cp $BackupInfoTxtFile ${RESTORE_BASE}/backup_info.txt
		CheckExit
	        MSG="Copy BackupInfoFile"
		cp $BackupInfoFile ${RESTORE_BASE}/backup/bahmni-postgres/backup.info
		CheckExit

		# Call doRestore Function
		   MSG="doRestore"
		   doRestore postgres
		   CheckExit
		
		# Check Restore status
		MSG="Check Final Restore status"
		psql -Uodoo odoo -c 'select name from res_company'
	        LogExit0
		
		   cd ..
		   [ -d ${RESTORE_BASE}/backup/bahmni-postgres/${backuprootFolder} ] && rm -rf ${RESTORE_BASE}/backup/bahmni-postgres/$backuprootFolder
		   [ -f ${RESTORE_BASE}/backup_info.txt ] && rm -f ${RESTORE_BASE}backup_info.txt
		   [ -f ${RESTORE_BASE}/backup/bahmni-postgres/BackupInfoFile ] && rm -f ${RESTORE_BASE}/backup/bahmni-postgres//backup.info
	done
}


case $DB in 
	mysql) Prefix=openmrs \
	           mysqlRestore ;;
	     pg) Prefix=openerp \
	           pgRestore ;;
esac
