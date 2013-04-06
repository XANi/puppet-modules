# Various hardware support



# Class: hw::iwlwifi
#
#  intel wifi firmware
class hw::iwlwifi {
    package {'firmware-iwlwifi':
        ensure => installed,
    }
}
