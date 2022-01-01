class bareos::fd (
    $fd_address = "0.0.0.0",
    $fd_password = local_pwgen('bareos::fd::director::pass',64),
    $mon_password = local_pwgen('bareos::fd::mon::pass',64),
)  {
    realize Apt::Source['bareos']
    file { '/etc/bareos/bareos-fd.d':
        ensure  => absent,
        recurse => true,
        purge   => true,
        backup => false,
        force => true,
    }
    file { '/etc/bareos/bareos-fd.conf':
        content => template('bareos/bareos-fd.conf'),
        mode => "640",
        owner => root,
        notify => Service['bareos-filedaemon'],
    }
    service { 'bareos-filedaemon':
        ensure => running,
        enable => true,
    }
    ensure_packages(['bareos-filedaemon'])
}