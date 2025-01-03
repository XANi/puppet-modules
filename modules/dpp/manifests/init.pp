class dpp (
    $manifest_from = 'shared',
    Array[String] $use_repos = ['private','shared'],
    $start_wait = 20,
    $minimum_interval = 120,
    $schedule_run = fqdn_rand(600)+3600,
    $poll_interval = 600,
    $mq_url = "tcp://127.0.0.1", #tls:// for encrypted, add user:pass@ before hostname
) {
    $manager_url = lookup('manager_url',undef,undef,false)
    $repo_config = lookup('dpp::repo')

    file {'/etc/dpp':
        ensure => directory,
        mode   => "700",
    }
    file { '/etc/dpp/config.yaml':
        content => template('dpp/dpp.conf.erb'),
        mode => "600",
        owner => root,
    }
    file {'/etc/dpp.conf':
        ensure => absent
    }

    file { '/etc/cron.daily/dpp_maint':
        ensure => absent,
    }
    file { '/etc/init.d/dpp':
        ensure  => absent,
    }
    file { '/etc/systemd/system/dpp.service':
        content => template('dpp/dpp.service'),
        mode    => "644",
        owner   => root,
        notify  => Exec['refresh-dpp-service'],
    }
    exec { 'refresh-dpp-service':
        command     => 'systemctl daemon-reload',
        refreshonly => true,
        logoutput   => true,
    }
    service { 'dpp':
        enable => true,
        provider => systemd,
        ensure => running,
    }
    util::service_disable {'puppet':;}
    logrotate::rule {'puppet_dpp':
        path         => '/var/log/puppet.log',
        rotate       => 7,
        rotate_every => 'day',
    }
    file {"/opt/dpp":
        ensure => directory
    }
    if !defined(File['/opt']) {
        file {"/opt":
            ensure => directory
        }
    }

    $source_map = $os['architecture'] ? {
        'i386'    => {
            url      => 'https://github.com/XANi/go-dpp/releases/download/v1.2.0/dpp.386',
            checksum => '12bdfb8179f3194594f0772fad807a5cfa81c9d13340550045448efe2cd5efcd',
        },
        'aarch64' => {
            url      => 'https://github.com/XANi/go-dpp/releases/download/v1.2.0/dpp.aarch64',
            checksum => '59b9eb59142c69f673215a09f121427d65f9cb4b487896e0f977e6d0a2b3ed39',
        },
        'amd64'   => {
            url      => 'https://github.com/XANi/go-dpp/releases/download/v1.2.0/dpp.amd64',
            checksum => 'd6468d0629e22e8c43fc6196714ba09f8ebcf4a564cf43c7f8a9ebb0e9555d27',
        },
        'arm'     => {
            url      => 'https://github.com/XANi/go-dpp/releases/download/v1.2.0/dpp.arm',
            checksum => '5a4fee8a1799d98d24fc38f6fbd4ec91098bfc8154a53b12b5586c5af3b70ada',
        },
    }


    stdlib::ensure_packages(['wget'])


    #dpp-generated facts
    file {'/etc/facter/facts.d/puppet_basemodulepath.txt': replace => false;}

    # puppetlabs in 2017 still can't figure out how to download a fucking file from a fucking internet, so use module that can
    # PUP-8299 PUP-8300
    archive { '/opt/dpp/dpp.current':
        source => $source_map["url"],
        checksum_type => "sha256",
        checksum => $source_map["checksum"],
        checksum_verify => true,
        notify => File['/opt/dpp/dpp'],
    }
    file {'/opt/dpp/dpp':
        ensure => file,
        source => '/opt/dpp/dpp.current',
        checksum => "sha256",
        checksum_value => $source_map["checksum"],
        mode => "755",
        backup => false,
        notify => Exec['restart-dpp'],
    }
    # for updates, we can't do that really from the main loop as it would kill running puppet
    cron {"restart-dpp":
        minute => fqdn_rand(59),
        hour => 20,
        weekday => 5,
        command => '[ -x /opt/dpp/dpp ] && systemctl restart dpp',
    }
    exec { 'restart-dpp':
        command => '/usr/bin/killall -USR2 dpp',
        refreshonly => true,
    }
}
