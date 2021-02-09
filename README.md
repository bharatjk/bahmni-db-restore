# bahmni-db-restore
Scripts to restore Bahmi DB
Copy all three files to /root on host.
== TO Automate Restore checking Schedule cron job using command.
== edit "cron-restore" file to amend the time.
  crontab cron-restore
== To run restore interactively for first time
   :set DB variable as "mysql" or "pg" and start Docker
   export DB=mysql or
   export DB=pg  
   docker run --privileged -d --name=bahmni$DB -e container=docker -v /root/:/data  bjkdoc/bahmni-$DB-restore 
== Log in to container
   docker exec -it bahmni$DB  bash
== run restore 
   /data/restore.sh 
   : Above script expects user backup files under /data/backup/customer
== Below are output log file for investigation are under /root on host and under /data in docker.
   Final Restore Status = mysql-Restore_status.txt, pg-Restore_status.txt
   cron outputs = restore-mysql-cron.log , restore-pg-cron.log
   Restore log = mysql-Restore.log , pg-Restore.log



