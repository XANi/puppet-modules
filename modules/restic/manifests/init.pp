class restic::backup::common(
    $s3_server,
    $monthly = 3,
    $weekly = 4,
    $backup_check = true,
)  {
    file { [
        '/etc/restic',
        '/etc/restic/jobinfo',
        '/var/spool/restic',
    ]:
        ensure => directory,
        force => true,
        recurse => true,
        purge => true,
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
    if $backup_check {
        monitor::cmd { 'backup':
            command => "/usr/local/bin/check_restic_backup",
            user    => 'root',
        }
    }
    tidy { '/etc/systemd/system':
        matches => ['restic*timer', 'restic*service'],
        recurse => 1,
        backup  => false,
    }
}


define restic::backup::file (
    # verify with systemd-analyze calendar --iterations=5 *-*-* 4:00
    $at_boot = false,
    $backup_schedule =  '*-*-* 4:00',
    $randomized_delay = "30m",
    $dir,
    $extra_flags='',
    $backup_tag='daily',
    $exclude_set = false,
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
    file { "/etc/restic/jobinfo/file-${title}":
        content => "${backup_tag} $dir"
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
    file { "/etc/restic/jobinfo/postgresql":
        content => "${backup_tag} postgresql"
    }
}

class restic::backup::mariadb (
    # verify with systemd-analyze calendar --iterations=5 *-*-* 4:00
    $backup_schedule =  '*-*-* 4:00',
    $randomized_delay = "30m",
    $extra_flags='',
    $backup_tag='daily',
) {
    systemd::service { "restic-mariadb":
        content => template('restic/restic-mariadb.service'),
    }
    systemd::timer { "restic-mariadb":
        content => template('restic/restic-mariadb.timer'),
    }
    file { "/etc/restic/jobinfo/mariadb":
        content => "${backup_tag} mariadb"
    }

}


define restic::exclude::set (
    Array $exclude,
) {
    file { "/etc/restic/exclude-${title}":
        content => inline_template('<%= @exclude.join("\n") + "\n" %>'),
    }
}

class restic::ignoreset::server ($extra = [])  {
    $x =  [
        '/dev',
        '/var/lib/bacula',
        '/proc',
        '/tmp',
        '/var/tmp',
        '/.journal',
        '/.fsck',
        '/var/cache',
        '/run',
        '/sys',
        '/dev',
        '/var/log',
        '/var/lib/bareos',
        '/var/lib/libvirt/images',
        '/var/lib/docker',
        '/var/lib/mysql',
        '/var/lib/postgresql',
    ]
    $set = flatten($x, $extra)
    restic::exclude::set { 'server':
        exclude => $set
    }
}