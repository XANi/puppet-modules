class restic::backup::common(
    $s3_server,
    $monthly = 3,
    $weekly = 4,
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
    file { '/etc/restic/maintenance.sh':
        content => template('restic/maintenance.sh'),
        mode    => "700",
    }
    systemd::service { 'restic-maintenance':
        content => template('restic/restic-maintenance.service'),
    }
    systemd::timer { 'restic-maintenance':
        content => template('restic/restic-maintenance.timer'),
    }
}