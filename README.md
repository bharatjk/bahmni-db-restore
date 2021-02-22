# bahmni-db-restore

This script tests the sanctity of Bahmni backup by restoring it using docker.
#
# inputs supported options are -d -c -e -n -l
#  
#    -d is for dbname, this is compulsory input,  currently supported input for this is [ db or mysql ]
# By default restore will scan backup files in /data/backup/* and try to restore for current week
#    All other options are optional
#  You can use only one option from -c or -e
#    -c Client name, this will  restore only for supplied client list. e.g. -ccust1 or -c"cust1,cust2"
#    -e Exclude client name, this will exclude given client from restore. e.g. -ecust1 or -e"cust1,cust2"
#  You can use only one option from -l or -n
#    -n Week number of backup file. e.g. -n2 [1-5] 
#    -l This will restore from last available backups in client folder. e.g. -l
# TO restore all client backup for current week
  Docker_run_bahmniDBRestore -dpg
# To restore Specific client only use -c Customername
  Docker_run_bahmniDBRestore -dpg -ccust03
# To restore Exclide Specific client use -e Customername
  Docker_run_bahmniDBRestore -dpg -ecust03
# To restore from Specific week number backup file use -n  e.g. openerp2.tar.gz
  Docker_run_bahmniDBRestore -dpg -n2
# To restore frnm last available backup file use -l
  Docker_run_bahmniDBRestore -dpg -l

## Basic Setup
1. Copy all four files to /root on host
2. Copy all the backups to be tested under /root/backup/customer1, /root/backup/customer2...etc
3. The script can be run in the following modes:


### Mode - Interactive
  
  For mysql restore
    
    Docker_run_bahmniDBRestore -dmysql
  
  For pg restore
    
    Docker_run_bahmniDBRestore -dpg

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



