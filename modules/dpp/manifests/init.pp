class dpp (
    $manifest_from = 'shared',
    $use_repos = false,
    $start_wait = 20,
    $minimum_interval = 120,
    $schedule_run = fqdn_rand(600)+3600,
    $poll_interval = 600,
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
    include '::archive'
    archive {"/opt/dpp/dpp-${architecture}":
        source => "https://github.com/XANi/go-dpp/releases/download/v0.0.2/dpp.${architecture}",
        checksum => $architecture ? {
            'amd64' => 'b7e236dc61478dd756326d9f107e9e4ceacfadf06f0ef342944eb1121d2ae2de',
            'arm'   => '68f6c61eec5faaa01022b66de2c69314312eefae7f5d4b1acb8730bfaf5bad1a',
            'arm64' => 'a27155ed4c2459e4983540ccf6a9076455c75e83e0bbf2101978c2f585e9dfa0',
        },
    }
    file {"/opt/dpp/dpp-${architecture}":
        mode => "755",
        owner => root,
    }

}
