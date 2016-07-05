class consul (
    $user = 'consul',
    $bind = '0.0.0.0',
    $dc   = 'home',
    $nodename = $fqdn,
    $client = '127.0.0.1',
    $advertise = false,
    $join = [],
    $join_wan = [],
    $server = false,
    $bootstrap = false,
    ) {
    # this should install package but maintainers are too lazy to bother, so I just install it manually
    # package {'consul': ensure => installed }
    file {'/etc/consul':
        ensure => directory,
        owner  => $user,
        group  => root,
        mode   => "640",
    }
    file {'/etc/consul/conf.d':
        ensure => directory,
        owner  => $user,
        group  => root,
        mode   => "640",
    }
    file {[
           '/usr/share/consul',
           '/usr/share/consul/ui',
           ]:
        ensure => directory,
        mode   => "644",
        owner  => root,
    }
    file {'/var/lib/consul':
        ensure => directory,
        owner  => $user,
        group  => root,
        mode   => "640",
    }
    file {'/etc/systemd/system/consul.service':
        content => template('consul/consul.systemd'),
        mode    => "644",
    }
}
