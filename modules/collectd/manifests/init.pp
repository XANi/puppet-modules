class collectd::client ($server) {
    include collectd::common
    service {'collectd':
        ensure => running,
        enable => true,
    }
    file {'/etc/collectd/collectd.conf':
        content => template('collectd/collectd.conf'),
        owner   => root,
        notify  => Service['collectd'],
    }
}

class collectd::common {
    package {'collectd':
        ensure => installed
    }
    file {'/etc/collectd/conf.d':
        ensure  => directory,
        mode    => 600,
        owner   => root,
        recurse => true,
        purge   => true,
        force   => true,
    }
    file {'/etc/default/collectd':
        content => template('collectd/default'),
    }

}
