# Class: hw::vaiopro
class hw::vaiopro {
    if !defined(File['/etc/X11/xorg.conf.d']) {
        file { '/etc/X11/xorg.conf.d':
            ensure => directory,
            mode   => 644,
            owner  => root,
        }
    }
    file{'/etc/X11/xorg.conf.d/99-vaio-synaptics.conf':
        content => template('hw/vaio-synaptics.conf'),
        owner   => root,
        mode    => 644,
    }
    # NFC
    package {'neard':
        ensure => installed,
    }
    # wifi
    package {'firmware-iwlwifi':
        ensure => installed,
    }
}
