#### Clone and copy all files to /root
#### Copy backups in the respective client folders in /root/backup/<client 1>… /root/backup/<client 2>… /root/backup/<client n>…
 - Clean /root/openmrs folder
#### Run using a suitable option
- Restore latest backupl
  - Docker_run_bahmniDBRestore –d<[mysq|l<[mysq|lpg]>]> -l
- Restore backup of specific week of the month 
  - Docker run_bahmniDBRestore -d<[mysq|lpg]> -n<week # of the month>
- Restore latest / specific week’s backup of a specific client
  - Docker_run_bahmniDBRestore -d<[mysq|lpg]> -c<client folder name> [-l | -n<specific week #>
- Restore all backups for current week
  - Docker_run_bahmniDBRestore -d<[mysq|lpg]>
- Restore all backups but exclude specific client
  - Docker_run_bahmniDBRestore -d<[mysq|lpg]> -e<client folder name to be excluded>
 
#### Check status in /root/<mysql|pg>-db-restore.txt and detailed log in /root/<client foldername-mysql|pg>-db-restore.log
#### SMS is sent listing failed backup - Need changes in phone numer URL etc. in Docker_run_bahmniDBRestore line 61
#### All containers are cleaned at the end of the script
