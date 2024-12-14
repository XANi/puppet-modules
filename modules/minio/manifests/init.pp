class minio::server(
    $access_key,
    $secret_key,
    $data_dir,
    $user,
    $group,
    $manage_user = true
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
    systemd::service {'minio':
        content => template('minio/minio.service');
    }
    service {'minio': ensure => running}
}