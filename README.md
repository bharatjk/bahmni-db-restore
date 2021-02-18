# bahmni-db-restore

This script tests the sanctity of Bahmni backup by restoring it using docker.

## Basic Setup
1. Copy all three files to /root on host
2. Copy all the backups to be tested under /root/backup/customer1, /root/backup/customer2...etc
3. The script can be run in the following modes:


### Mode - Interactive
  
  For mysql restore
    
    Docker_run_bahmniDBRestore mysql
  
  For pg restore
    
    Docker_run_bahmniDBRestore pg

### Mode - Using docker command
  On Host to restore mysql or pg set DB depending on which database (mysql/pg) is to restored and run docker.
    
    export DB=mysql
    docker run --privileged -d --name=bahmni$DB -e container=docker -v /root/:/data bjkdoc/bahmni-$DB-restore
    docker exec -it bahmni$DB bash

  On the docker image
    
     /data/restore.sh 
  
### Mode - Automate Restore checking Schedule cron job 
1. edit "cron-restore" file to amend the time.

       crontab cron-restore

### Generated Logs
1. Below are output log file for investigation are under /root on host and under /data in docker.
   
        Final Restore Status = mysql-Restore_status.txt, pg-Restore_status.txt
        Restore log = mysql-Restore.log , pg-Restore.log
        cron outputs = restore-mysql-cron.log , restore-pg-cron.log



