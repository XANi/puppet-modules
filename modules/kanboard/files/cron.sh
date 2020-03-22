#!/bin/bash
# <%=  __FILE__.gsub(/.*?modules\//,'puppet://modules/') %>
cd /var/www/kanboard/
sudo -u www-data ./cli cronjob

