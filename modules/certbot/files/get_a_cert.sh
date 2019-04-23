#!/bin/bash
# puppet
SELF=$(readlink -f $0)

if [ "z$1" = "zreload" ] ; then
    for dir in $(find  /etc/letsencrypt/live/ -maxdepth 1 -mindepth 1 -type d); do
        cat $dir/privkey.pem $dir/fullchain.pem > $dir/certandkey.pem
    done
    /bin/bash -c 'sleep 1m ;systemctl reload haproxy' &
else
    certs=$(perl -e 'print map {"-d $_ "} @ARGV' $@)
    /usr/bin/certbot certonly \
                     --cert-name $1 \
                     --keep-until-expiring  \
                     --expand \
                     --agree-tos  \
                     --non-interactive \
                     --no-self-upgrade \
                     --post-hook "$SELF reload" \
                     --webroot -w /var/www/certbot  \
                     $certs
fi
