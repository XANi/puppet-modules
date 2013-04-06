# Class: wireless::master
#
# stuff needed for linux to work as AP
#
class wireless::master (
    $interface = 'wlan0',
    $ssid      = 'setupme',
    $country   = 'US',
    $hw_mode   = 'g',
    $channel   = fqdn_rand(8,1),
    $bridge    = false,
    $password,
) {
    include wireless::util
    package {'hostapd':
        ensure => 'installed',
    }
    file {'/etc/hostapd/hostapd.conf':
        content => template('wireless/hostapd.conf'),
        mode    => 600,
        owner   => root,
        notify  => Service['hostapd'],
    }
    file {'/etc/default/hostapd':
        content => template('wireless/hostapd.default'),
        mode    => 644,
        owner   => root,
        notify  => Service['hostapd'],
    }
    service {'hostapd':
        ensure => running,
        enable => true,
        require => [
                    File['/etc/hostapd/hostapd.conf'],
                    File['/etc/default/hostapd'],
                    ]
    }
}
