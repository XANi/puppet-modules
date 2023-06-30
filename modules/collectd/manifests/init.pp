class collectd::common (
    $version = "installed",
    $interval = 10,
    $run = true,
) {
    package {"collectd":
        ensure => $version,
    }
    user { "collectd":
        system => true,
        managehome => false,
        home =>  "/var/lib/collectd/home",
    }
#    # some plugins get wonky sadly (mqtt in 5.7 have problems reconnecting)
#    cron { 'restart-collectd':
#        command => "/bin/systemctl restart collectd",
#        hour    => fqdn_rand(23),
#        minute  => fqdn_rand(59),
#    }
    file {'/etc/collectd':
        ensure => directory,
        mode   => "711", # +x so we can use this dir for non-root-running plugin config
    }
    file {'/etc/collectd/collectd.conf.d':
        ensure => directory,
        mode   => "700",
        purge => true,
        recurse => true,
        force => true,
    }
    file { '/etc/collectd/collectd.conf.d/local.conf':
        replace => false,
        owner   => root,
        mode => "644",
    }
    service { 'collectd':
        ensure => $run ? {
            true  => running,
            false => undef,
        },
        enable => $run,
    }
    if !$run {
        notify{"collectd autostart disabled":;}
    }
    # file { '/usr/share/collectd/types.db':
    #     source   => "puppet:///modules/collectd/types.db",
    #     mode     => "644",
    #     owner    => root,
    #     group    => root,
    #     require  => Package['collectd'],
    #     notify => Service['collectd'],
    # }
    file { '/var/lib/collectd':
        ensure => directory,
        mode   => "771",
    }
    file { '/etc/collectd/custom_types.db':
        source   => "puppet:///modules/collectd/custom_types.db",
        mode     => "644",
        notify => Service['collectd'],
    }
    file { '/etc/collectd/collectd.conf':
        content => template('collectd/collectd.conf'),
        mode    => "600",
        notify => Service['collectd'],
    }
    file { '/etc/collectd/collectd.conf.d/0000-filters.conf':
        content => template('collectd/filters.conf'),
        mode    => "600",
        notify => Service['collectd'],
    }
    if $virtual == "physical" {
        ensure_packages([
            'libsensors5',
            'lm-sensors',
            'libatasmart4',
        ])
        if $processors['models'][0] =~ /Intel/ {
            file { '/etc/modules-load.d/collectd-msr.conf':
                content => "msr\n",
                owner   => root,
            }
        }
    }

}

define collectd::conf(
    $content = undef,
    $source = undef,
    $prio = 1000,
) {
    $padded_prio = sprintf('%04d', $prio)
    include collectd::common
    if !$content and !$source {
        fail('need $content or $source')
    }
    if $content {
        $content_c = "# ${title}\n${content}\n"
    }
    file { "/etc/collectd/collectd.conf.d/${padded_prio}-${title}.conf":
        source  => $source,
        content => $content_c,
        mode    => "600",
        notify => Service['collectd'],
    }
}

define collectd::network::send(
    $address,
    $port=25826,
) {
    collectd::conf { "network-${title}":
        content => "<Plugin network>\nServer \"${address}\" \"${port}\"\n</Plugin>\n"
    }
}

define collectd::plugin::load (
) {
    collectd::conf { "plugin-${title}":
        content => "LoadPlugin ${title}\n",
        prio => 0,
    }
}

class collectd::client ($server) {
    collectd::network::send{'server': address => $server}
    include collectd::common
}

define collectd::plugin::exec (
    $command,
    $user = 'nobody',
    $args = false,
)  {
    include collectd::common
    collectd::conf { "exec_${title}":
        content => template('collectd/p/exec.conf')
    }
}



define collectd::plugin::mqtt(
    $host,
    $port = 1883,
    $user = "mqtt",
    $pass = "mqtt",
    $topic = 'collectd/#',
    $clean_session= true,
) {
    collectd::conf { "mqtt_${title}":
        content => template('collectd/p/mqtt.conf')
    }

}

class collectd::plugin::ping::common (
    $interval = 2.0,
    $timeout = 1.9,
) {
    collectd::conf { "ping_common":
        content => template('collectd/p/ping_common.conf'),
        prio => 500,
    }
}
define collectd::plugin::ping {
    include collectd::plugin::ping::common
    collectd::conf { "ping_${title}":
        content => template('collectd/p/ping.conf'),
    }
}
class collectd::plugin::virt {
    collectd::conf { "virt":
        content => template('collectd/p/virt.conf'),
    }
}

class collectd::plugin::perl::common (
    $interval = 2.0,
    $timeout = 1.9,
) {
    file { [
        '/etc/collectd/perl',
        '/etc/collectd/perl/Collectd',
        '/etc/collectd/perl/Collectd/Plugins',
    ]:
        ensure => directory,
        owner => 'root',
        group => 'root',
        mode => "750",
    }
    collectd::conf { "perl_common":
        content => template('collectd/p/perl_common.conf'),
        prio => 500,
    }
}
define collectd::plugin::perl {
    include collectd::plugin::perl::common
    file { "/etc/collectd/perl/Collectd/Plugins/${title}.pm":
        source => "puppet:///modules/collectd/perl/${title}.pm",
        owner => "root",
        mode => "640",
    }
    collectd::conf { "perl_${title}":
        content => template('collectd/p/perl.conf'),
    }
}
class collectd::plugin::sensors (
    $ignored_sensors = [],
) {
    collectd::conf { "sensors":
        content => template('collectd/p/sensors.conf'),
    }
}