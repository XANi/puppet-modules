class rsyslog::common {
    package {'rsyslog':
        ensure => installed
    }
}

define rsyslog::log (
    $prio = '1000',
    $template = "rsyslog/parts/${title}",
    $params   = {}
) {
    $pad_prio = sprintf('%04d',$prio)
    file {"/etc/rsyslog.d/${pad_prio}-${title}.conf":
        content => template($template),
        mode    => 644,
    }
}
