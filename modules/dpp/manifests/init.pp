class dpp (
    $manifest_from = 'shared',
    $use_repos = ['private','shared'],
    $manager_url  = false,
    $start_wait = 20,
    $minimum_interval = 120,
    $schedule_run = fqdn_rand(600,3000),
    $poll_interval = 20,
)
    {
    $repo_config = hiera('repo')
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
}

