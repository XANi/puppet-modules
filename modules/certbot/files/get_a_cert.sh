#!/bin/bash
# puppet
certs=$(perl -e 'print map {"-d $_ "} @ARGV' $@)
/usr/bin/certbot certonly \
    --keep-until-expiring  \
    --expand \
    --agree-tos  \
    --non-interactive \
    --no-self-upgrade \
    --post-hook "/bin/systemctl reload haproxy" \
    --webroot -w /var/www/certbot  \
    $certs

for dir in $(ls -d /etc/letsencrypt/live/*); do
    cat $dir/privkey.pem $dir/fullchain.pem > $dir/certandkey.pem
done