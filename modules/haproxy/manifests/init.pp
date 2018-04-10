
class haproxy::server {
    package {'haproxy': ensure => installed}
    service { 'haproxy':
        ensure => running,
        enable => true,
    }
    concat { '/etc/haproxy/haproxy.cfg':
        mode => "644",
        notify => Service['haproxy'],
    }
    concat::fragment{ 'haproxy_header':
        target  => '/etc/haproxy/haproxy.cfg',
        content => template('haproxy/header'),
        order   => 0,
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
