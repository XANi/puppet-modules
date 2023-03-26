class common::server (
    # serve ntp to others
    $ntp_server = false,
    $backup = true,
)  {
    class { 'apt':
        purge => {
            'sources.list'   => true,
            'sources.list.d' => true,
            'preferences'    => false,
            'preferences.d'  => false,
        }
    }
    apt::conf {"no-suggested":
        content => 'APT::Install-Suggests "0";'
    }
    include core
    include core::monitoring
    realize Apt::Source['main-stable']
    include puppet
    include common::utils
    include common::cleanup
    include util::shell
    include user::common
    include motd
    include util::tmpreaper
    if $backup {
        include bareos::fd
    }
    include unattended_upgrades
    include debsecan
    include collectd::client
    if $ntp_server {
        include ntp::server
    } else {
        include ntp::client
    }
    # cleanup that shit, some packages depend on it for no good reason
    package { ['apache2', 'apache2-bin']:
        ensure => absent,
    }
    file {'/usr/local/bin/e':
        target => '/usr/bin/zile',
    }
    $interval = 3600 + fqdn_rand(20)
    if !defined(Class['dpp']) {
        class { dpp:
            manifest_from => 'private',
            poll_interval => $interval,
            minimum_interval => 300,
        }
    }
    rsyslog::log {'puppet':;}
    rsyslog::log {'dpp':;}
}

