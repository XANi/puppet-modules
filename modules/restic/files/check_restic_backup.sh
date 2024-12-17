#!/bin/bash
# puppet managed
export PATH="$PATH:/usr/local/bin"
source /etc/restic/env
LC_ALL=C
CURRENT_DATE=$(date "+%F")
YESTERDAY=$(date "+%F" -d yesterday)
EXIT=0
if [ -z "$1" ]; then
    expected=1
else
   expected=$1
fi
backups_in_date=$(restic snapshots --latest 1|grep -P "($CURRENT_DATE|$YESTERDAY)" |wc -l)
if [ "$backups_in_date" -eq 0 ] ; then
    echo "no backup found!";
    exit 2
fi
if [ "$backups_in_date" -lt $expected ] ; then
    echo "expected $expected backups, got $backups_in_date"
    restic snapshots --latest 1|grep -P "($CURRENT_DATE|$YESTERDAY)"
    exit 1
else
    echo "all OK: $backups_in_date"
exit 0
fi
