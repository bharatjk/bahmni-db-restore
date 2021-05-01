#!/bin/bash
#Script to restore mysql backup and write output to status file
#

#BASEDIR=/root
#. /root/verifyInputs.sh
export BASEDIR=/data
. /data/verifyInputs.sh 


if [ -n  "$WeekNum" ] ; then thisWeek=$WeekNum
elif [ -n "$lastbackup" ] ; then thisWeek="*"
  else thisWeek=$((($(date +%-d)-1)/7+1))
fi
#thisWeek=$((($(date +%-d -d"last Sun")-1)/7+1))

echo RESTORE in restore.sh=$RESTORE OnlyClient=$OnlyClient DB=$DB Exclude=$Exclude WeekNum=$WeekNum lastbackup=$lastbackup GREP=$GREP 
echo thisWeek=$thisWeek

#TZ is set via Docker run by copying host timezone file.Set below TZ to over ride.
#export TZ=Asia/Kolkata

SRC_BACKUPDIR=${BASEDIR}/backup
Outfile=${BASEDIR}/${DB}-Restore_status.txt

CheckExit ()
{
     if [ $? != 0 ] ;then
	echo "FAILED: $MSG" >>$Restorelog
	echo "Failed,`date +%D,%T`,$Client,$backuprootFolder,Failed Task: $MSG " >>$Outfile
	cd ..
	CONTINUE=continue
	#BackupTarFile=""
	#BackupInfoTxtFile=""
	#BackupInfoFil=""
      else
	CONTINUE=""
     fi
}

LogExit0 ()
{
	if [ $? = 0 ] ;then 
	    echo "Success,`date +%D,%T`,$Client,$backuprootFolder,$BackupTarFile,$BackupInfoTxtFile" >>$Outfile 
            rm -f $Restorelog
	else
	    echo "Failed,`date +%D,%T`,$Client,$backuprootFolder,$BackupTarFile,$BackupInfoTxtFile" >>$Outfile
	fi
}

doRestore ()
{

	OPTIONS=$1
	   # Restore  task
	   echo "bahmni -i local restore --restore_type=db --options=${OPTIONS} --strategy=pitr --restore_point=$backuprootFolder "
	   bahmni -i local restore --restore_type=db --options=${OPTIONS} --strategy=pitr --restore_point=$backuprootFolder 2>&1 >>$Restorelog

}

mysqlRestore ()
{ 
BackupTarFile=${Prefix}${thisWeek}.tar.gz
BackupInfoTxtFile=${Prefix}_backup_info${thisWeek}.txt
cd $SRC_BACKUPDIR

  for Client in `ls -l|grep ^d|awk '{print $NF}'|$GREP`
     do
       export Restorelog=${BASEDIR}/${Client}-${DB}-Restore.log
       MSG="cd $Client"
       cd "$Client"
       CheckExit
       $CONTINUE
       echo PWD=$PWD
       MSG="Check last backup files or set backup files"
       if [ -n "$lastbackup" ] ; then
          thisWeek=`ls -t $BackupTarFile  2>/dev/null|head -1|cut -c8` 
       	    if [ -n "$thisWeek" ] ; then
	       BackupTarFile=${Prefix}${thisWeek}.tar.gz
	       BackupInfoTxtFile=${Prefix}_backup_info${thisWeek}.txt	
	    else
	    	CheckExit
		$CONTINUE
	    fi
	 else    
	       BackupTarFile=${Prefix}${thisWeek}.tar.gz
	       BackupInfoTxtFile=${Prefix}_backup_info${thisWeek}.txt
         fi
	   		
	MSG="Check input backup files"
    	[  -s  $BackupTarFile -a  -s  $BackupInfoTxtFile ] 
	    CheckExit
           echo BackupTarFile=$BackupTarFile BackupInfoTxtFile=$BackupInfoTxtFile	
	    $CONTINUE
	
		#Extract bckup to /data/openmrs
	       tar xf $BackupTarFile -C /
		   MSG="Get backuprootFolder name"
		   backuprootFolder=`ls /data/openmrs/`
		   CheckExit

		 MSG="Copy BackupInfoTxtFile"
		cp $BackupInfoTxtFile  /data/openmrs/backup_info.txt
		CheckExit
		$CONTINUE
	
          # Call doRestore Function
		   MSG="doRestore"
		   doRestore openmrs
		   CheckExit
		   $CONTINUE

		   #Check Restore status
		   MSG="Check Final Restore status"
		   mysql -B -u root -pP@ssw0rd openmrs -e "select * from location;"
		   LogExit0
		$CONTINUE
		   
		   cd ..
		   [ -d /data/openmrs/${backuprootFolder} ] && rm -rf /data/openmrs/$backuprootFolder
		   [ -f /data/openmrs/backup_info.txt ] && rm -f /data/openmrs/backup_info.txt
done
}


pgRestore ()
{
 BackupTarFile=${Prefix}${thisWeek}.tar.gz
 BackupInfoTxtFile=${Prefix}backup_info${thisWeek}.txt
 BackupInfoFile=${Prefix}bfbackup.info${thisWeek}
 RESTORE_BASE=/var/lib/pgbackrest/
[ ! -d /var/log/backrest/  ] && mkdir /var/log/backrest/ 
cd $SRC_BACKUPDIR

for Client in `ls -l|grep ^d|awk '{print $NF}'|$GREP`
   do
     export Restorelog=${BASEDIR}/${Client}-${DB}-Restore.log
       MSG="cd $Client"
       cd "$Client"
       CheckExit
       MSG="Set backup files"
       if [ -n "$lastbackup" ] ; then 
          thisWeek=`ls -t $BackupTarFile  2>/dev/null|head -1|cut -c8` 
            if [ -n "$thisWeek" ] ; then
		BackupTarFile=${Prefix}${thisWeek}.tar.gz
		BackupInfoTxtFile=${Prefix}backup_info${thisWeek}.txt
		BackupInfoFile=${Prefix}bfbackup.info${thisWeek}
             else
		CheckExit
		$CONTINUE
            fi
	 else
	   BackupTarFile=${Prefix}${thisWeek}.tar.gz
	   BackupInfoTxtFile=${Prefix}backup_info${thisWeek}.txt
	   BackupInfoFile=${Prefix}bfbackup.info${thisWeek}
	fi
	    MSG="Check input backup files"
    	[  -f  $BackupTarFile -a  -f  $BackupInfoTxtFile -a  -f  $BackupInfoFile ] 
	    CheckExit
		$CONTINUE


		#Extract bckup to /var/lib/pgbackrest/ 
		tar xf $BackupTarFile -C /
		MSG="Get backuprootFolder name"
		backuprootFolder=`ls  -d ${RESTORE_BASE}/backup/bahmni-postgres/2*|awk -F/ '{print $NF}'`
		CheckExit
		$CONTINUE
		
		MSG="Copy BackupInfoTxtFile"
		cp $BackupInfoTxtFile ${RESTORE_BASE}/backup_info.txt
		CheckExit
		$CONTINUE
		
	    #MSG="Copy BackupInfoFile"
		cp $BackupInfoFile ${RESTORE_BASE}/backup/bahmni-postgres/backup.info
		CheckExit
		$CONTINUE

		# Call doRestore Function
		   MSG="doRestore"
		   doRestore postgres
		   CheckExit
		   $CONTINUE
			
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
	mysql) Prefix=openmrs mysqlRestore ;;
           pg) Prefix=openerp pgRestore ;;
esac
exit 0
