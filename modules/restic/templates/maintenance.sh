#!/bin/bash
# puppet managed template, for more info 'puppet-find-resources $filename'
# <%=  __FILE__.gsub(/.*?modules\//,'puppet://modules/') %>
export PATH="$PATH:/usr/local/bin"
export HOME=/root
source /etc/restic/env
# just in case/for first run
restic unlock || restic init
restic forget --tag "" --keep-daily 7 --keep-weekly <%= @weekly %>  --keep-monthly <%= @monthly %>
restic forget --tag hourly --keep-hourly 48 --keep-daily 14 --keep-weekly <%= @weekly %>  --keep-monthly <%= @monthly %> --keep-within <%= @monthly %>m
restic forget --tag daily --keep-daily 7 --keep-weekly <%= @weekly %>  --keep-monthly <%= @monthly %> --keep-within <%= @monthly%>m
restic forget --tag weekly --keep-daily 1 --keep-weekly <%= @weekly %>  --keep-monthly <%= @monthly %> --keep-within <%= @monthly%>m
restic prune
