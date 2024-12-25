class kanboard::common {
     stdlib::ensure_packages(['php-sqlite3', 'php-gd', 'php-mbstring', 'php-xml','php-zip'])
    file { '/etc/cron.daily/kanboard':
        source => 'puppet:///modules/kanboard/cron.sh',
        mode   => "0755",
        ensure => present,
    }
}

class kanboard::server {
    include kanboard::common
}
