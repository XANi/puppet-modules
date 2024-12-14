class restic::backup::common(
    $s3_server,
)  {
    file { '/etc/restic':
        ensure => directory,
        force => true,
        recurse => true,
        owner => 'root',
        mode  => '700'
    }
    file { '/etc/restic/env.template':
        content => template('restic/env.template')
    }

}