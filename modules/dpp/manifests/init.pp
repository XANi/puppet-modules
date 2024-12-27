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
            url      => 'https://github.com/XANi/go-dpp/releases/download/v0.1.8/dpp.386',
            checksum => 'd7ff94fb38c3206940bb06e99fdb87f351094519eee5fba5cbc2847cd1aa8226',
        },
        'aarch64' => {
            url      => 'https://github.com/XANi/go-dpp/releases/download/v0.1.8/dpp.aarch64',
            checksum => 'f4cdacefb14af6d8d2da3f656cedb349dfb01a5dcf90cac8b1a53b1182b9b4c9',
        },
        'amd64'   => {
            url      => 'https://github.com/XANi/go-dpp/releases/download/v0.1.8/dpp.amd64',
            checksum => 'c9b4b2bec023905a050179a5e6e6b8bada3f0bb7cbd100505be88385f75649e5',
        },
        'arm'     => {
            url      => 'https://github.com/XANi/go-dpp/releases/download/v0.1.8/dpp.arm',
            checksum => '74bea8ec236ab96922addffcb1b331df2738e4231bc2402e88852685917c6157',
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
