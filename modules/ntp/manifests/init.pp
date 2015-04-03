
class ntp::chrony (
    $upstream = hiera('ntp_server','pl.pool.ntp.org'),
    $server = false,

    ) {
    package { 'ntpdate':
        ensure => installed;
    }
    package {'ntp':
        ensure => absent,
    }
    package {'chrony':
        ensure => installed,
    }
    file {'/etc/chrony/chrony.conf':
        content => template('ntp/chrony.conf'),
        owner   => root,
        mode    => 644,
    }
    service {'chrony':
        enable => true,
        ensure => running,
    }
    file { '/etc/cron.hourly/ntpdate':
        ensure => absent,

    }
}


class ntp::server {
    class {
        'ntp::chrony':
            server => true,
    }
}
class ntp::client {
    include ntp::chrony
}
