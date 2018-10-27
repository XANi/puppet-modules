#!/bin/bash
# puppet

if [ "z$1" = "zreload" ] ; then
    for dir in $(ls -d /etc/letsencrypt/live/*); do
        cat $dir/privkey.pem $dir/fullchain.pem > $dir/certandkey.pem
    done
    /bin/bash -c 'sleep 1m ;systemctl reload haproxy' &
else
    certs=$(perl -e 'print map {"-d $_ "} @ARGV' $@)
    /usr/bin/certbot certonly \
                     --keep-until-expiring  \
                     --expand \
                     --agree-tos  \
                     --non-interactive \
                     --no-self-upgrade \
                     --post-hook "$0 reload" \
                     --webroot -w /var/www/certbot  \
                     $certs
fi
