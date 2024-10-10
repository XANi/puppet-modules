class core::desktop {
    include core
}


class core {
    include core::apt::base
    realize Apt::Source['main-stable']
    realize Apt::Source['main-stable-security']
    realize Apt::Source['firefox']

    # for various packages
    package {'lsb-release':
        ensure => installed
    }
    file {'/root/.zile':
       content => template('core/zile'),
    }
    file {[
        '/root/emacs',
        '/root/emacs/backup',
    ]:
        ensure => directory,
    }

}

class core::apt::base {
    file {'/etc/apt/gpg-keys-puppet':
        source => 'puppet:///modules/core/gpg/apt',
        recurse => true,
        purge => true
    }
    create_resources("@apt::source",lookup('repos'))
    file {'/etc/apt/apt.conf.d/99-zpuppet.conf':
        ensure => absent,
    }
    cron { 'apt-cache-autoclean':
        ensure => absent
    }
    file {'/etc/cron.weekly/puppet-apt-cleanup':
        content => "#!/bin/bash\n# puppet managed\napt-get autoclean >/dev/null 2>&1\nfind /var/cache/apt/archives -mtime +90 -type f -delete >/dev/null 2>&1\n",
        mode => "755",
    }
    file { '/etc/cron.weekly/puppet-apt-updates':
        ensure => absent
    }
    package { [
        'debian-keyring',
        'debian-archive-keyring',
    ]:
        ensure => latest
    }

}

class core::ssdsave {
    mount { '/var/log/tmp':
        options => 'size=100m',
        device      => 'none',
        fstype      => 'tmpfs',
        ensure      => mounted,
    }
    logrotate::rule {'log-tmp':
        path => '/var/log/tmp/*.log',
        rotate => 24,
        rotate_every => 'day',
        minsize => '1M',
        su => true,
        su_owner => "root",
        su_group => "adm",
        compress => true,
        sharedscripts => true,
        postrotate => 'find /var/log/tmp -mtime +30 -delete',
    }
    rsyslog::log {'tmp-log':
        prio => 10,
        ;
    }

}

class core::monitoring {
    include monitor::client
}
