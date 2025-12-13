class garage::server(
    #$access_key,
    #$secret_key,
    $admin_token,
    #$metrics_token,
    $data_dir,
    #$api_listen_host='127.0.0.1',
    #$console_address='0.0.0.0:9001',
    $manage_user = true,
    $manage_datadir = true,
    $prometheus_url = false,
) {
    if $manage_user {
        user { garage:
            system     => true,
            shell      => '/bin/false',
            home       => $data_dir,
            managehome => true,
            gid        => garage,
        }
        group { garage:
            system => true,
        }
    }
    if $manage_datadir == true {
        file { $data_dir:
            ensure => directory,
            owner  => garage,
            group  => garage,
            mode   => "750",
        }
    }
    file { '/etc/garage.toml':
        content => template('garage/garage.toml'),
        mode    => "600",
        owner   => "garage"
    }

    #file { '/var/log/garage':
    #    ensure => directory,
    #    owner  => garage,
    #    group  => garage,
    #    mode   => "750",
    #}
    systemd::service {'garage':
        content => template('garage/garage.service'),
        notify => Service['garage'],
    }
    service {'garage':
        ensure => running,
        enable => true,
    }
}