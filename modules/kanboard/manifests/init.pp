class kanboard::common {
    ensure_packages(['php-sqlite', 'php-gd', 'php-mbstring', 'php-xml','php-zip'])
    file { '/etc/cron.daily/kanboard':
        source => 'puppet:///modules/kanboard/cron.sh',
        mode   => "0755",
        ensure => present,
    }
}

class kanboard::server {
    include kanboard::common
}
