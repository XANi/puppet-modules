class commento::server (

) {
    realize Group["commento"]
    realize User["commento"]
    systemd::service { 'commento':
        content => template('commento/commento.service'),
    }
    service { 'commento':
        ensure => running,
        enable => true,
    }

}