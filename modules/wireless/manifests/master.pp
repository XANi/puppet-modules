# Class: wireless::master
#
# stuff needed for linux to work as AP
#
class wireless::master {
    include wireless::util
    package {'hostapd':
        ensure => 'installed',
    }
}
