#!/bin/bash
# puppet managed file

if [ -z "$1" ] ; then
    echo "specify vmstorage port"
fi

PORT=$1


SNAPSHOT_ID=$(curl -s http://127.0.0.1:${PORT}/snapshot/create | jq -r .snapshot)
echo "made snapshot ${SNAPSHOT_ID} on 127.0.0.1:${PORT}" |logger -t vmstorage_backup
