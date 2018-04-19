class homeassistant::server {
    user { 'homeassistant':
        ensure => present,
        home   => '/opt/homeassistant',
        shell  => '/bin/bash',
    }
    file { '/opt/homeassistant':
        ensure => directory,
        mode   => "700",
        owner  => "homeassistant",
        group => "homeassistant",
    }
    systemd::service { 'homeassistant':
        content => template('homeassistant/homeassistant.service'),
    }
    service { 'homeassistant':
        ensure => running,
        enable => true,
    }


    package {['python3-pip','python3-venv']: ensure => installed}
}