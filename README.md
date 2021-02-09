# bahmni-db-restore
Scripts to restore Bahmi DB
Copy all three files to /root on host.
== TO Schedule Daily Restore run below commnd to install cron job.
  crontab cron-restore
== To run restore interactivly 
   :set DB variable as mysql or pg for erp and start Docker
   export DB=mysql or
   export DB=pg  
   docker run --privileged -d --name=bahmni$DB -e container=docker -v /root/:/data  bjkdoc/bahmni-$DB-restore 
   : Log in to container
   docker exec -it bahmni$DB  bash
   : run restore 
   /data/restore.sh 
   : Above script expects user backup files under /data/backup/customer



