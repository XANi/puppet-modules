#!/bin/bash
if ! which pwgen ; then echo install pwgen ; exit 1 ;fi
if ! which envsubst ; then echo install envsubst ; exit 1 ; fi
export S3_SECRET=`pwgen -s 32 1`
export RESTIC_SECRET=`pwgen -s 32 1`
if [ ! -e /etc/restic/env ] ; then
    touch /etc/restic/env
    chmod go-rwx /etc/restic/env
    cat /etc/restic/env.template |envsubst > /etc/restic/env
fi
