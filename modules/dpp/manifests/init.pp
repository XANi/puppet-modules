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
        command => '/bin/bash -c "cd /usr/src;git clone http://github.com/XANi/dpp.git"',
        creates => '/usr/src/dpp/.git/config',
        logoutput => true,
    }
    file { '/etc/cron.daily/dpp_cleanup':
        content => template('dpp/cron.cleanup.erb'),
        mode    => 755,
    }
    util::service_disable {'puppet':;}
}
