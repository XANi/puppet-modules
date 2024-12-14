class minio::server(
    $access_key,
    $secret_key,
    $base_dir,
    $user,
    $group,
    $manage_user = true
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
    systemd::service {'minio':
        content => template('minio/minio.service');
    }
    service {'minio': ensure => running}
}