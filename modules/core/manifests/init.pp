class core::desktop {
    include core
}


class core {
    include core::apt::base
    file {'/root/.zile':
       content => template('core/zile'),
    }

}

class core::apt::base {
    create_resources("@apt::source",hiera('repos'))
    file {'/etc/apt/apt.conf.d/99-zpuppet.conf':
        ensure => absent,
    }

}

class core::server (
    $ntp_client = true,
    $collectd_client = true,
) {
    include core
    include core::monitoring
    apt::conf {"no-suggested":
        content => 'APT::Install-Suggests "0";'
    }
    if $collectd_client {
        include collectd::client
    }
    if $ntp_client {
        include ntp::client
    }
    $interval = 600 + fqdn_rand(20)
    class { dpp:
        manifest_from => 'private',
        poll_interval => $hostname ? {
            default => $interval,
        },
        minimum_interval => $hostname ? {
           hastur => 120,
           default => fqdn_rand(120,240),
        },
    }
    include common::utils
    include common::cleanup
    include util::shell
    include user::common
    include motd
    include puppet
    rsyslog::log {'puppet':;}
    rsyslog::log {'dpp':;}
        file {'/usr/local/bin/e':
        target => '/usr/bin/zile',
    }

}


class core::monitoring {
    package {[
        'monitoring-plugins'
    ]: ensure => installed
    }
}
