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
    file { '/usr/local/bin/check_restic_backup':
        source => 'puppet:///modules/restic/check_restic_backup.sh',
        mode   => "755",
        owner  => root,
    }
}

define restic::backup::file (
    # verify with systemd-analyze calendar --iterations=5 *-*-* 4:00
    $backup_schedule =  '*-*-* 4:00',
    $randomized_delay = "30m",
    $directory,
    $extra_flags='',
    $backup_tag='daily',
) {
    if $title !~ /^[a-zA-Z0-9_\-]+$/ {
        fail("only alphanumeric plus -_ names for systemd units sake")
    }
    systemd::service { "restic-file-${title}":
        content => template('restic/restic-file.service'),
    }
    systemd::timer { "restic-file-${title}":
        content => template('restic/restic-file.timer'),
    }
}
class restic::backup::postgresql (
    # verify with systemd-analyze calendar --iterations=5 *-*-* 4:00
    $backup_schedule =  '*-*-* 4:00',
    $randomized_delay = "30m",
    $extra_flags='',
    $backup_tag='daily',
) {
    systemd::service { "restic-postgresql":
        content => template('restic/restic-postgresql.service'),
    }
    systemd::timer { "restic-postgresql":
        content => template('restic/restic-postgresql.timer'),
    }
}