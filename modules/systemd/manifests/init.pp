
# in general im not a fan of cultivating old bugs
# but i like typing 4 letters instead of 8 to poweroff my machine and aliases sont work great with sudo
class systemd::poweroff_on_halt {
    file { '/lib/systemd/system/systemd-halt.service':
        source => '/lib/systemd/system/systemd-poweroff.service',
        mode   => "644",
        owner  => root,
    }
}
class systemd::common {
    exec {"systemd-reload":
        command => "systemctl daemon-reload",
        refreshonly => true,
    }
}


define systemd::service::override (
    $service_name = $title,
    $service = false,
    $unit = false,
    $install = false,
    $prio = 1000,
    ) {
    $padded_prio = sprintf('%04d',$prio)# 4 -> 0004
    include systemd::common
    if !defined (File["/etc/systemd/system/${service_name}.service.d/"]) {
        file {"/etc/systemd/system/${service_name}.service.d/":
            ensure  => directory,
            recurse => true,
            purge   => true,
            mode    => "644",
        }
    }
    file {"/etc/systemd/system/${service_name}.service.d/${padded_prio}-${title}.conf":
        content => template('systemd/service'),
        mode => "644",
        owner => root,
        group => root,
        notify => Exec["systemd-reload"],
    }

}

define systemd::service (
    $content = undef,
    $source  = undef,
    ) {
    include systemd::common
    if !$content and !$source {
        $content_c = template("systemd/service/${title}.conf")
    }
    else {
        $content_c = $content
    }

    file {"/etc/systemd/system/${title}.service":
        content => $content_c,
        source  => $source,
        mode    => "644",
        notify  => Exec["systemd-reload"]
    }
}
define systemd::timer (
    $content = undef,
    $source  = undef,
) {
    include systemd::common
    if !$content and !$source {
        $content_c = template("systemd/timer/${title}.conf")
    }
    else {
        $content_c = $content
    }

    file {"/etc/systemd/system/${title}.timer":
        content => $content_c,
        source  => $source,
        mode    => "644",
        notify  => Exec["systemd-reload"]
    }
    service { "${title}.timer":
        enable => true,
    }
}
