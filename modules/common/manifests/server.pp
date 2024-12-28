class common::server (
    # serve ntp to others
    $ntp_server = false,
    $backup = true,
)  {
    if !defined(Class['apt']) {
        class { 'apt':
            purge => {
                'sources.list'   => true,
                'sources.list.d' => true,
                'preferences'    => false,
                'preferences.d'  => false,
            }
        }
    }
    apt::conf {"no-suggested":
        content => 'APT::Install-Suggests "0";'
    }
    include core
    include core::monitoring
    realize Apt::Source['main-stable']
    realize Apt::Source['main-stable-security']
    include puppet
    include common::utils
    include common::cleanup
    include util::shell
    include user::common
    include motd
    include util::tmpreaper
    include tmux
    if $backup {
        include restic::backup::common
    }
    include unattended_upgrades
    include debsecan
    include collectd::client
    if $ntp_server {
        include ntp::server
    } else {
        include ntp::client
    }
    # cleanup that shit, some packages depend on it for no good reason
    package { ['apache2', 'apache2-bin']:
        ensure => absent,
    }
    file {'/usr/local/bin/e':
        target => '/usr/bin/zile',
    }
    $interval = 3600 + fqdn_rand(20)
    if !defined(Class['dpp']) {
        class { dpp:
            manifest_from => 'private',
            poll_interval => $interval,
            minimum_interval => 300,
        }
    }
    rsyslog::log {'puppet':;}
    rsyslog::log {'dpp':;}
    $vpn_nodes = lookup('vpn::nodes')
    if $networking['hostname'] in $vpn_nodes {
        ensure_packages(['wireguard','wireguard-tools'])
        $vpn_nodes.each |$n| {
            $wg_key = "@wireguard::${n}::pub"
            $pubk = messdb_read($wg_key)
            if $pubk {
                file { "/tmp/key_${n}":
                    content => $pubk
                }
            }
            if $n == $networking['hostname'] {
                $privk = messdb_read("wireguard::${n}::keypair")
                if $pubk == undef or $privk == undef {
                    notify { "key for $n not generated":; }
                    $keydata = generate_ed25519_keypair()
                    if $keydata {
                        messdb_write($wg_key,$keydata['pub'])
                        messdb_write("wireguard::${n}::keypair",$keydata)
                    } else {
                        notify { "key generation not worked":; }
                    }
                }
            }
        }
    }
}

