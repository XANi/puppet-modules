class rustfs::server(
    $access_key,
    $secret_key,
    $data_dir,
    $user = 'rustfs',
    $group = 'rustfs',
    $api_listen_host='127.0.0.1',
    $console_address='0.0.0.0:9001',
    $manage_user = true,
    $manage_datadir = true,
    $prometheus_url = false,
) {
    if $manage_user {
        user { $user:
            system     => true,
            shell      => '/bin/false',
            home       => $data_dir,
            managehome => true,
            gid        => $group,
        }
        group { $group:
            system => true,
        }
    }
    if $manage_datadir == true {
        file { $data_dir:
            ensure => directory,
            owner  => $user,
            group  => $group,
            mode   => "750",
        }
    }
    file { '/var/log/rustfs':
        ensure => directory,
        owner  => $user,
        group  => $group,
        mode   => "750",
    }
    systemd::service {'rustfs':
        content => template('rustfs/rustfs.service'),
        notify => Service['rustfs'],
    }
    service {'rustfs':
        ensure => running,
        enable => true,
    }
}