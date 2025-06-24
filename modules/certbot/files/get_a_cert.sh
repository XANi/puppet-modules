#!/bin/bash
# puppet
certs=$(perl -e 'print map {"-d $_ "} @ARGV' $@)
/usr/bin/certbot certonly \
                 --cert-name $1 \
                 --keep-until-expiring  \
                 --expand \
                 --agree-tos  \
                 --email xani+certbot@devrandom.pl \
                 --non-interactive \
                 --no-self-upgrade \
                 --webroot -w /var/www/certbot  \
                 $certs
# if any of the certs got updated, update the certandkey bundle
RELOAD=0
for dir in $(find  /etc/letsencrypt/live/ -maxdepth 1 -mindepth 1 -type d); do
   if [ "$dir/fullchain.pem" -nt "$dir/certandkey.pem" ] ; then
       echo "updating cert in $dir"
       RELOAD=1
       cat $dir/privkey.pem $dir/fullchain.pem > $dir/certandkey.pem
    fi
done

# and reload haproxy

if [ "$RELOAD" = "1" ]; then
    echo "certs changed, reloading haproxy"
    systemctl reload haproxy
fi
