class sysctl::common {
    concat { '/etc/sysctl.d/puppet.conf':
        mode  => "644",
        owner => root,
    }
    exec { 'sysctl-update':
        command     => '/sbin/sysctl -p /etc/sysctl.d/puppet.conf',
        refreshonly => true,
        logoutput   => true,
        subscribe   => Concat['/etc/sysctl.d/puppet.conf']
    }
}
define sysctl (String $val) {
    include sysctl::common
    concat::fragment { "sysctl-${title}":
        target  => '/etc/sysctl.d/puppet.conf',
        content => "${title} = ${val}\n",
        notify => Exec['sysctl-update'],
    }
}



