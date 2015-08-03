class network {
    if $::osfamily =~ /(?i:debian)/ {
        include network::common::debian
    }
    elsif $::lsbdistid =~ /(?i:redhat)/ {
        include network::common::redhat
    }
}


class network::common::debian {
    file {'/etc/network/interfaces.d/':
        ensure  => directory,
        recurse => true,
        purge   => true,
        owner   => root,
        mode    => 644,
    }
}

class network::common::redhat {
    fail("rhel/centos not supported yet")
}
