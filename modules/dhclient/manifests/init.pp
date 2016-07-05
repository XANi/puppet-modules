# Class: dhclient
#
# hiera:
#   dhcp:
#       domain-name: sth
#       host-name: sth-else

class dhclient {
    $dhcp = hiera('dhcp', false)
    file { '/etc/dhcp/dhclient.conf':
        content => template('dhclient/dhclient.conf.erb'),
        owner   => root,
        group   => root,
        mode    => "644",
    }
}
