# Class: dhclient
#
# hiera:
#   dhcp:
#       domain-name: sth
#       host-name: sth-else

class dhclient {
    $dhcp = lookup('dhcp',undef,undef, false)
    file { '/etc/dhcp/dhclient.conf':
        content => template('dhclient/dhclient.conf.erb'),
        owner   => root,
        group   => root,
        mode    => "644",
    }
}
