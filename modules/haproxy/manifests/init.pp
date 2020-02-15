
class haproxy::server (
    $global_content = template('haproxy/global.haproxy'),
    $defaults_content = template('haproxy/defaults.haproxy'),
) {
    package {'haproxy': ensure => installed}
    service { 'haproxy':
        ensure => running,
        enable => true,
    }
    concat { '/etc/haproxy/haproxy.cfg':
        mode => "644",
        notify => Service['haproxy'],

    }
    if $global_content {
        concat::fragment { 'haproxy_global':
            target  => '/etc/haproxy/haproxy.cfg',
            content => "${global_content}\n",
            order   => 0,
        }
    }
    if $global_content {
        concat::fragment { 'haproxy_defaults':
            target  => '/etc/haproxy/haproxy.cfg',
            content => "${defaults_content}\n",
            order   => 1,
        }
    }
}

define haproxy::config (
    $template = $title,
    $content = template("haproxy/${title}"),
    $order = 1000,
)   {
    concat::fragment{ "haproxy_${title}":
        target  => '/etc/haproxy/haproxy.cfg',
        content =>  $content,
        order   => $order,
    }
}
