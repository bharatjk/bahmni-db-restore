#!/bin/bash
#
#

echo "Inside verifyINput.sh $@"
function CheckExit ()
{
     if [ $? != 0 ] ;then
        echo "FAILED: $MSG" 
        exit 1
     fi
}

while getopts ":d:c:n:e:l" ARGS; do
    case $ARGS in
    d)  DB="$OPTARG" ;;
    c)  OnlyClient="$OPTARG" ;;
    e)  Exclude="$OPTARG" ;;
    n)  WeekNum="$OPTARG" ;;
    l)  lastbackup="true" ;;
    *) echo "Error: `basename $0` Incorrect inputs"; exit 1;;
    esac
done

verifyClien () {
for C in `echo $OnlyClient|sed s'/,/ /'`
  do
    if [ ! -s /$BASEDIR/backup/$C/*.tar.gz 2>/dev/null ] ; then
      echo "Error: Missing OnlyClient Folder $C or Backup tar files"
      exit 1
    fi
done
}

if [ -z "$DB" ] ; then 
  echo "Error: Missing -d [DBNAME]"
  echo "Usage: `basename $0` -d [pg|mysql]"
  exit 1
fi
RESTORE="-d$DB "

GREP=""
if [ -n "$OnlyClient"  -a  -n "$Exclude" ] ; then 
  echo "Error:Can use only one option from -c and -e"
  exit 1
elif [ -n  "$OnlyClient" ] ; then verifyClien ; RESTORE="$RESTORE -c$OnlyClient"; GREP="egrep -w `echo $OnlyClient|sed s'/,/|/'`"
elif [ -n "$Exclude" ] ; then RESTORE="$RESTORE -e$Exclude"; GREP="egrep -wv `echo $Exclude|sed s'/,/|/'`"
else GREP=xargs
fi


if [ -n "$lastbackup" -a -n "$WeekNum" ] ; then
  echo "Error:Can use only one option from -l and -n"
  exit 1
elif [ -n "$lastbackup" ] ; then  RESTORE="$RESTORE -l"
elif [ -n "$WeekNum" ]  ; then   RESTORE="$RESTORE -n$WeekNum"
fi

export RESTORE OnlyClient DB Exclude WeekNum lastbackup
