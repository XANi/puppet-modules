class network (
    $manage_global = false # also manage global file
)   {
    if $::osfamily =~ /(?i:debian)/ {
        include network::common::debian
    }
    elsif $::lsbdistid =~ /(?i:redhat)/ {
        include network::common::redhat
    }
}



class network::common::debian {
    require network
    file {'/etc/network/interfaces.d/':
        ensure  => directory,
        recurse => true,
        purge   => true,
        owner   => root,
        mode    => "644",
    }
    if $network::manage_global {
        concat { '/etc/network/interfaces':
            ensure => present,
        }
        concat::fragment {'network interface header':
            target  => '/etc/network/interfaces',
            content => template('network/if-debian-main'),
            order   => '00',
        }
    }

}

class network::common::redhat {
    fail("rhel/centos not supported yet")
}

