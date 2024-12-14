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
    stdlib::ensure_packages([
        'pwgen',
        'restic',
    ])
    file { '/etc/restic/init-env.sh':
        content => template('restic/init-env.sh'),
        mode => "755"
    }
        
    file { '/etc/restic/env.template':
        content => template('restic/env.template')
    }
    file { '/etc/restic/env':
        mode  => "600",
        owner => root,
    }
    exec { 'generate-restic-secrets':
        command  => '/etc/restic/init-env.sh',
        require => [File['/etc/restic/init-env.sh'], File['/etc/restic/env.template']],
        creates  => '/etc/restic/env'
    }

}