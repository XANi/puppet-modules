
class haproxy::server (
    $global_content = template('haproxy/global.haproxy'),
    $defaults_content = template('haproxy/defaults.haproxy'),
) {
    package {'haproxy': ensure => installed}
    service { 'haproxy':
        ensure => running,
        enable => true,
    }
    concat { '/etc/haproxy/.haproxy.cfg.v':
        mode => "600",
        notify => Service['haproxy'],
        order => "numeric",
        owner => root,
    }
    file { '/etc/haproxy/haproxy.cfg':
        subscribe => Concat['/etc/haproxy/.haproxy.cfg.v'],
        source    => '/etc/haproxy/.haproxy.cfg.v',
        mode      => "640",
        owner     => "haproxy",
        group     => "haproxy",
        validate_cmd => '/usr/sbin/haproxy -c -f %',
    }
    if $global_content {
        concat::fragment { 'haproxy_global':
            target  => '/etc/haproxy/.haproxy.cfg.v',
            content => "${global_content}\n",
            order   => "0000",
        }
    }
    if $global_content {
        concat::fragment { 'haproxy_defaults':
            target  => '/etc/haproxy/.haproxy.cfg.v',
            content => "${defaults_content}\n",
            order   => "0001",
        }
    }
}

define haproxy::config (
    $template = $title,
    $content = template("haproxy/${title}"),
    $order = 1000,
)   {
    concat::fragment{ "haproxy_${title}":
        target  => '/etc/haproxy/.haproxy.cfg.v',
        content =>  $content,
        order   => $order,
    }
}
