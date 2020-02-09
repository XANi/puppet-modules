class commento::server (
    $origin_domain,
    $port = 3010,
    $postgres_url = "postgres:///commento?host=/var/run/postgresql/",
) {
    realize Group["commento"]
    realize User["commento"]
    systemd::service { 'commento':
        content => template('commento/commento.service'),
    }
    # squeaky secrets there so put it away from /etc
    file { '/opt/commento/cfg':
        ensure => directory,
        owner  => commento,
        mode   => "700",
    }
    file { '/opt/commento/cfg/env.cfg':
        content => "# puppet managed file
COMMENTO_POSTGRES=${postgres_url}
",
        owner => "commento",
        mode => "0600",
    }
    service { 'commento':
        ensure => running,
        enable => true,
    }

}