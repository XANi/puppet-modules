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
    $checksum = $architecture ? {
        'amd64' => '53c30784921a6e3d4ef4a261482ed7538095a0916bcbefe9c9fc323277bc86e2',
        'arm'   => '68f6c61eec5faaa01022b66de2c69314312eefae7f5d4b1acb8730bfaf5bad1a',
        'arm64' => 'a27155ed4c2459e4983540ccf6a9076455c75e83e0bbf2101978c2f585e9dfa0',
    }
    file {'/opt/dpp/dpp.sha256sum':
        content => "$checksum  /opt/dpp/dpp.${architecture}.tmp\n"
    }

    exec {"get-dpp-archive":
        command => "wget -O /opt/dpp/dpp.${architecture}.tmp https://github.com/XANi/go-dpp/releases/download/v0.0.2/dpp.${architecture} && chmod +x /opt/dpp/dpp.${architecture}.tmp || rm /opt/dpp/dpp.${architecture}.tmp",
        creates => "/opt/dpp/dpp.${architecture}.tmp",
        logoutput => true,
        notify => Exec['verify-dpp-archive'],
    }
    exec{ "verify-dpp-archive":
        command => "sha256sum -c /opt/dpp/dpp.sha256sum && mv /opt/dpp/dpp.${architecture}.tmp /opt/dpp/dpp || rm /opt/dpp/dpp.${architecture}.tmp",
        refreshonly => true,
        logoutput => true,
        require => File['/opt/dpp/dpp.sha256sum'],
    }
    file {'/opt/dpp/dpp':
        mode => "755",
    }


}
