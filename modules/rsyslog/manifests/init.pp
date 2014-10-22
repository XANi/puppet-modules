class rsyslog::common {
    package {'rsyslog':
        ensure => installed
    }
    service {'rsyslog':
        ensure => running,
        enable => true,
    }
}

define rsyslog::log (
    $prio = '1000',
    $template = "rsyslog/parts/${title}",
    $params   = {}
) {
    require rsyslog::common
    $pad_prio = sprintf('%04d',$prio)
    file {"/etc/rsyslog.d/${pad_prio}-${title}.conf":
        content => template($template),
        mode    => 644,
        notify  => Service['rsyslog'],
    }
}
