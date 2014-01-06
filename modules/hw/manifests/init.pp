# Various hardware support



# Class: hw::iwlwifi
#
#  intel wifi firmware
class hw::iwlwifi {
    package {'firmware-iwlwifi':
        ensure => installed,
    }
}

# disable power maangement, makes wifi on rpi awfully slow
class hw::8192cu::power {
    file {'/etc/modprobe.d/8192cu.conf':
        content => template('hw/8192cu.conf'),
        mode    => 644,
    }
}
