# Class: wireless::master
#
# stuff needed for linux to work as AP
#
class wireless::master (
    $interface    = 'wlan0',
    $ssid         = 'setupme',
    $country_code = 'US',
    $hw_mode      = 'g',
    $channel      = fqdn_rand(8,1),
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
    }
}
