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
            url      => 'https://github.com/XANi/go-dpp/releases/download/v0.1.5/dpp.386',
            checksum => '5bbd643cdcfe8bd59c87944a11204eab7a1127942f4c88b6f97d682435ad7c87',
        },
        'aarch64' => {
            url      => 'https://github.com/XANi/go-dpp/releases/download/v0.1.5/dpp.aarch64',
            checksum => '6a59198f9a0260d0480c9d152282c614788db904550475c1323199aea6171343',
        },
        'amd64'   => {
            url      => 'https://github.com/XANi/go-dpp/releases/download/v0.1.6/dpp.amd64',
            checksum => '346667755ccb2b5cc7f68aee8f96f9a2a2ce71518603cf1af68b7e3c2a2d85d9',
        },
        'arm'     => {
            url      => 'https://github.com/XANi/go-dpp/releases/download/v0.1.5/dpp.arm',
            checksum => '1d19d7430b3d63eb92e8f6854bc45eae54ccfa01dd669a88937e668d0351c992',
        },
    }


    ensure_packages(['wget'])


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
