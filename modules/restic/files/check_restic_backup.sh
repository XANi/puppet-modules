#!/bin/bash
# puppet managed
export PATH="$PATH:/usr/local/bin"
source /etc/restic/env
LC_ALL=C
CURRENT_DATE=$(date "+%F")
YESTERDAY=$(date "+%F" -d yesterday)
EXIT=0
expected=$(find /etc/restic/jobinfo -type f |wc -l)
tmpf=$(mktemp)
restic snapshots --latest 1|grep -P "($CURRENT_DATE|$YESTERDAY)" >$tmpf
backups_in_date=$(cat $tmpf |wc -l)

if [ "$backups_in_date" -eq 0 ] ; then
    echo "no backup found!";
    cat $tmpf
    rm -f $tmpf
    exit 2
fi
if [ "$backups_in_date" -lt $expected ] ; then
    echo "expected $expected backups, got $backups_in_date"
    cat $tmpf
    rm -f $tmpf
    exit 1
else
    echo "all OK: $backups_in_date"
    cat $tmpf
    rm -f $tmpf
    exit 0
fi
