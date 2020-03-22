class kanboard::common {
    ensure_packages(['php-sqlite', 'php-gd', 'php-mbstring', 'php-xml','php-zip'])
    file { '/etc/cron.daily/kanboard':
        source => 'puppet://puppet/modules/kanboard/cron.sh',
        mode   => "0755",
    }
}

class kanboard::server {
    include kanboard::common
}
