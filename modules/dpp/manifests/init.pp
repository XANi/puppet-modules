class dpp (
    $manifest_from = 'shared',
    Array[String] $use_repos = ['private','shared'],
    $start_wait = 20,
    $minimum_interval = 120,
    $schedule_run = fqdn_rand(600)+3600,
    $poll_interval = 600,
    $mq_url = "tcp://127.0.0.1", #tls:// for encrypted, add user:pass@ before hostname
) {
    $manager_url = hiera('manager_url',false)
    $repo_config = lookup('repo')

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
            url      => 'https://github.com/XANi/go-dpp/releases/download/v0.0.6/dpp.amd64',
            checksum => 'd6c0cc1c22e040ea35efd6d2dc30298dcf0a00cb30262caa7ceae356582c3e05',
        },
        'aarch64' => {
            url      => 'https://github.com/XANi/go-dpp/releases/download/v0.0.6/dpp.aarch64',
            checksum => '08997f5140a472e81f9951ef7c3d0f424ce5e2bc7f7d1abda406716f20eac713',
        },
        'arm'     => {
            url      => 'https://github.com/XANi/go-dpp/releases/download/v0.0.6/dpp.arm',
            checksum => '36242c72b228b5e3010b31587fc5b68a3a8b1bb69314a084dc78f89dc7a76ec3',
        },
        'i386'    => {
            url      => 'https://github.com/XANi/go-dpp/releases/download/v0.0.6/dpp.386',
            checksum => '097da00c7956b33f09560217beb85e758e938b45ca01795ecb9232650d1f5458',
        }
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
    }
    # for updates, we can't do that really from the main loop as it would kill running puppet
    cron {"restart-dpp":
        minute => fqdn_rand(59),
        hour => 20,
        command => '[ -x /opt/dpp/dpp ] && systemctl restart dpp',
    }
}
