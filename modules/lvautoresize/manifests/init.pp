class lvautoresize {
    file { '/usr/local/bin/lvautoresize':
        source => 'puppet:///modules/lvautoresize/lvautoresize.pl',
        mode   => "755",
        owner  => "root",
    }
    file { '/etc/lvautoresize.conf':
        replace => false,
        content => template('lvautoresize/lvautoresize.conf'),
        mode    => "644",
        owner   => root,
    }
    file { '/etc/lvautoresize.d':
        ensure  => directory,
        mode    => "644",
        owner   => root,
        force   => true,
        recurse => true,
        purge   => true,
    }
    file { '/etc/lvautoresize.d/local.conf':
        content => template('lvautoresize/local.conf'),
        mode    => "644",
        owner   => root,
        replace => false,
    }
    cron { 'lvautoresize':
        command => '/usr/local/bin/lvautoresize',
        minute => '*/30',
    }


}