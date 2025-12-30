# @summary configure BIRD >= 2.0
class bird3 (
    $version = "installed",
    $service_ipv4 = true,
    $service_ipv6 = false,
    $iso_time_format = true,
    $debug_protocols = false,
    $debug_channels = false,
    String $router_id = $ipaddress,
) {
    package { "bird3":
        ensure => $version
    }
    package {'bird': ensure => absent}
    service { 'bird':
        ensure => running,
        restart => 'service bird reload',
        enable => true,
        require => Exec['validate-bird-config'],
    }
    file { '/etc/bird':
        ensure => directory,
        owner  => bird,
        group  => bird,
        mode   => "750",
    }
    file {'/etc/bird/conf.d':
        ensure => directory,
        owner => bird,
        group => bird,
        mode => "750",
        purge  => true,
        recurse => true,
        notify => [Exec['reload-bird']],
    }
    file { '/etc/bird/bird.conf':
        content => template('bird3/bird.conf'),
        owner => bird,
        group => bird,
        mode => "640",
        notify => [Exec['reload-bird']],
    }
    # bird3 unit file has checks for config validity.
    # but we do them anyway so the puppet will alert us on that
    exec { 'reload-bird':
        command     => 'service bird reload',
        require     => Exec['validate-bird-config'],
        refreshonly => true,
    }
    # this is here so there will be alert when config is bad
    exec { 'validate-bird-config':
        unless     => '/usr/sbin/bird -p -c /etc/bird/bird.conf',
        command    => '/usr/sbin/bird -p -c /etc/bird/bird.conf',
        logoutput  => true,
    }
    #syslog::log { 'bird':; }
    #realize Logrotate::Rule['bird']
}

# @param trie enable trie tables, makes RPKI/recursive lookups faster at cost of memory
define bird3::table(
   # $trie = false # not available in stable debian *yet*
    $type = "ipv4",
) {
    file {"/etc/bird/conf.d/0000-table-${title}.conf":
        content => template('bird3/table.conf'),
        owner   => bird,
        group   => bird,
        mode    => "640",
        notify  =>  [Exec['validate-bird-config'],Exec['reload-bird']],
    }
}


define bird3::config (
    $prio = false,
    $config,
)   {
    include bird3

    if $prio {
        $prio_c = $prio
    }
    else {
        # filters,tables need to be defined before they are used
        if $title =~ /filter|table/ {
            $prio_c = 500
        }
        elsif $title =~ /bfd/ {
            $prio_c = 999
        }
        else {
            $prio_c = 1000
        }
    }

    $padded_prio = sprintf('%04d',$prio_c) # 4 -> 0004
    file {"/etc/bird/conf.d/${padded_prio}-${title}.conf":
        content => template('bird3/part.conf'),
        owner   => bird,
        group   => bird,
        mode    => "640",
        notify  =>  [Exec['validate-bird-config'],Exec['reload-bird']],
    }
}
