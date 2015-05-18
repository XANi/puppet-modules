class dpp (
    $manifest_from = 'shared',
    $use_repos = false,
    $start_wait = 20,
    $minimum_interval = 120,
    $schedule_run = fqdn_rand(600,3000),
    $poll_interval = 120,
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

    file { '/etc/dpp.conf':
        content => template('dpp/dpp.conf.erb'),
        mode => 600,
        owner => root,
    }

    exec {'checkout-repo':
        # use http, most "compatible" with crappy firewall/corporate networks
        command => '/bin/bash -c "mkdir -p /opt;cd /opt;git clone http://github.com/XANi/dpp.git"',
        creates => '/opt/dpp/.git/config',
        logoutput => true,
    }
    file { '/etc/cron.daily/dpp_maint':
        content => template('dpp/cron.maint.erb'),
        mode    => 755,
    }
    file { '/etc/cron.daily/dpp_cleanup':
        ensure => absent,
    }

    file { '/etc/init.d/dpp':
        ensure  => absent,
    }
    file { '/etc/systemd/system/dpp.service':
        content => template('dpp/dpp.service'),
        mode    => 644,
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
        ensure => running,
    }
    if !defined(Package['libssl-dev']) {
        package { 'libssl-dev':
            ensure => installed,
        }
    }
    util::service_disable {'puppet':;}
    logrotate::rule {'puppet_dpp':
        path         => '/var/log/puppet.log',
        rotate       => 7,
        rotate_every => 'day',
    }
}
