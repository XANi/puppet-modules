#!/bin/bash
# puppet managed
export PATH="$PATH:/usr/local/bin"
if [ -z "$1" ] ;then
    echo "usage: $0 machine_name"
    exit 2
fi
expected=$2
if [ -z "$2" ] ; then
    expected=1
fi

if [ ! -e "/etc/restic/env_$1" ] ; then
    echo "need file  /etc/restic/env_$1  to exist and contain correct creds"
    exit 2
fi
source "/etc/restic/env_$1"
LC_ALL=C
CURRENT_DATE=$(date "+%F")
YESTERDAY=$(date "+%F" -d yesterday)
EXIT=3
tmpf=$(mktemp)
restic --no-lock snapshots --latest 1|grep -P "($CURRENT_DATE|$YESTERDAY)" >$tmpf
backups_in_date=$(cat $tmpf |wc -l)

if [ "$backups_in_date" -eq 0 ] ; then
    echo "no backup found!";
    EXIT=2
elif [ "$backups_in_date" -eq $expected ] ; then
    echo "$backups_in_date backups OK"
    EXIT=0
elif [ "$backups_in_date" -lt $expected ] ; then
    echo "expected $expected backups, got $backups_in_date"
    EXIT=1
elif [ "$backups_in_date" -gt $expected ] ; then
    echo "more than expected [$expected] backup count: $backups_in_date"
    EXIT=1
else
    echo "should not be here"
    EXIT=2
fi
cat $tmpf
rm -f $tmpf
exit $EXIT