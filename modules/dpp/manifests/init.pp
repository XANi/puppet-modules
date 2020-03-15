class dpp (
    $manifest_from = 'shared',
    $use_repos = false,
    $start_wait = 20,
    $minimum_interval = 120,
    $schedule_run = fqdn_rand(600)+3600,
    $poll_interval = 600,
    $mq_url = "tcp://127.0.0.1", #tls:// for encrypted, add user:pass@ before hostname
) {
    $manager_url = hiera('manager_url',false)
    $repo_config = hiera('repo')

    if !$use_repos {
        $use_repos_a = hiera('dpp::use_repos',false)
        if !$use_repos_a {
            $use_repos_c = ['private','shared']
        } else {
            notify{'Upgrade to something newer pls':;}
            $use_repos_c = $use_repos_a
        }
    }
    else {
        $use_repos_c = $use_repos
    }
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
        'amd64'   => {
            url      => 'https://github.com/XANi/go-dpp/releases/download/v0.0.5/dpp.amd64',
            checksum => '2c323b4a9c78cecb35e28aa60a037ab2875cc419e299e0b7ee05af96c2451b3a',
        },
        'aarch64' => {
            url      => 'https://github.com/XANi/go-dpp/releases/download/v0.0.5/dpp.aarch64',
            checksum => 'e29480ac929bedd125c2993d5da0a0b036c959c71b906a00dc3103f9f91a40ef',
        },
        'arm'     => {
            url      => 'https://github.com/XANi/go-dpp/releases/download/v0.0.5/dpp.arm',
            checksum => 'c01132064e5d6e509e08b9d7265f53c160b51bea41115fc344e8b82687fd1217',
        },
    }





    #dpp-generated facts
    file {'/etc/facter/facts.d/puppet_basemodulepath.txt': replace => false;}
    # puppetlabs in 2017 still can't figure out how to download a fucking file from a fucking internet, just put it in repo
    # PUP-8299 PUP-8300
    file {'/opt/dpp/dpp':
        source => $source_map["url"],
        checksum => "sha256",
        checksum_value => $source_map["checksum"],
        mode => "755",
        backup => false,
   }
    # for updates, we can't do that really from the main loop as it would kill running puppet
    cron {"restart-dpp":
        minute => fqdn_rand(59),
        hour => 20,
        command => '[ -x /opt/dpp/dpp ] && systemctl restart dpp',
    }
}
