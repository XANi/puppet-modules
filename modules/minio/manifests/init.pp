class minio::server(
    $access_key,
    $secret_key,
    $base_dir,
    $user,
    $group,
    $api_listen_host='127.0.0.1',
    $console_address='0.0.0.0:9001',
    $manage_user = true,
    $scanner_speed = 'default',
    $scanner_cycle = false,
) {
    if $manage_user {
        user { $user:
            system     => true,
            shell      => '/bin/false',
            home       => $base_dir,
            managehome => true,
            gid        => $group,
        }
        group { $group:
            system => true,
        }
    }
    $data_dir = "${base_dir}/data"
    file { $data_dir:
        ensure => directory,
        owner  => $user,
        group  => $group,
        mode   => "750",
    }
    systemd::service {'minio':
        content => template('minio/minio.service'),
        notify => Service['minio'],
    }
    service {'minio':
        ensure => running,
        enable => true,
    }
}