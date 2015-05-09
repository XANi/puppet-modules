class consul::common ($user='consul') {
    # this should install package but maintainers are too lazy to bother, so I just install it manually
    # package {'consul': ensure => installed }
    file {'/etc/consul':
        ensure => directory,
        owner  => $user,
        group  => root,
        mode   => 640,
    }
    file {'/etc/consul/conf.d':
        ensure => directory,
        owner  => $user,
        group  => root,
        mode   => 640,
    }
    file {'/var/lib/consul':
        ensure => directory,
        owner  => $user,
        group  => root,
        mode   => 640,
    }
}
class consul::server {
    require consul::common
}
