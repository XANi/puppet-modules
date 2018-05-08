class collectd::client ($server, $config = false) {
    include collectd::common
    service {'collectd':
        ensure => running,
        enable => true,
    }
    if $config {
        file { '/etc/collectd/collectd.conf':
            content => $config,
            owner   => root,
            notify  => Service['collectd'],
        }
    } else {
        file { '/etc/collectd/collectd.conf':
            content => template('collectd/collectd.conf'),
            owner   => root,
            replace => false,
            notify  => Service['collectd'],
        }
    }
}

class collectd::common {
    package {'collectd':
        ensure => latest,
    }
    package {'liboping0':
        ensure => installed,
    }
    file {'/etc/collectd/conf.d':
        ensure  => directory,
        mode    => "644",
        owner   => root,
        recurse => true,
        purge   => true,
        force   => true,
    }
    file {'/etc/collectd/conf.d/local.conf':
        replace => false,
        content => template('collectd/empty.conf');
    }
    file {'/etc/default/collectd':
        content => template('collectd/default'),
    }

}
