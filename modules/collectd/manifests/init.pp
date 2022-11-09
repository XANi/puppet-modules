class collectd::client ($server, $config = false) {
    include collectd::common
    service {'collectd':
        ensure => running,
        enable => true,
    }
    # some plugins get wonky sadly (mqtt in 5.7 have problems reconnecting)
    cron { 'restart-collectd':
        command => "/bin/systemctl restart collectd",
        hour    => fqdn_rand(23),
        minute  => fqdn_rand(59),
    }
    if $config {
        file { '/etc/collectd/collectd.conf':
            content => $config,
            owner   => root,
            notify  => Service['collectd'],
        }
    } else {
        file { '/etc/collectd/collectd.conf':
            content => template('collectd/config/default.conf'),
            owner   => root,
            replace => false,
            notify  => Service['collectd'],
        }
    }
}

class collectd::server($config) {
    include collectd::common
    service {'collectd':
        ensure => running,
        enable => true,
    }
    # some plugins get wonky sadly (mqtt in 5.7 have problems reconnecting)
    cron { 'restart-collectd':
        command => "/bin/systemctl restart collectd",
        hour    => fqdn_rand(23),
        minute  => fqdn_rand(59),
    }
    file { '/etc/collectd/collectd.conf':
        content => $config,
        owner   => root,
        replace => false,
        notify  => Service['collectd'],
    }
}

class collectd::common {
    package {'collectd':
        ensure => latest,
    }
    package {'liboping0':
        ensure => installed,
    }
    file {'/etc/collectd/conf.d':
        ensure  => directory,
        mode    => "644",
        owner   => root,
        recurse => true,
        purge   => true,
        force   => true,
    }
    file {'/etc/collectd/conf.d/local.conf':
        replace => false,
        content => template('collectd/empty.conf');
    }
    file {'/etc/default/collectd':
        content => template('collectd/default'),
    }
    @collectd::plugin::load {
        'exec':;
    }
    user { 'collectd':
        system => true,
        ensure => present
    }
}
define collectd::plugin (
    $prio = 1000,
    $params = {},
    $template = $title,
)  {
    $padded_prio = sprintf('%04d',$prio)
    $file_content = template("collectd/plugins/${template}.conf")
    file { "/etc/collectd/conf.d/${padded_prio}-${title}.conf":
        content => "${file_content}\n", # always add trailing newline
        mode    => "600",
        owner   => root,
        notify  => Service['collectd'],
    }
}
define collectd::plugin::load (
    $interval = false,
)   {
    $padded_prio ="0000"
    $plugin = $title
    $file_content = template("collectd/load_plugin.conf")
    file { "/etc/collectd/conf.d/${padded_prio}-load_${title}.conf":
        content => "${file_content}\n", # always add trailing newline
        mode    => "600",
        owner   => root,
        notify  => Service['collectd'],
    }
}

define collectd::plugin::exec (
    $command,
    $user = 'nobody',
    $args = false,
)  {
    require collectd::common
    realize Collectd::Plugin::Load[exec]
    collectd::plugin {
        "exec_${title}":
            template => 'exec',
            params => {
                command => $command,
                user    => $user,
                args    => $args,
            },
            notify => Service['collectd'],
    }
}
