define util::add_user_to_group ($user,$group) {
    exec { "add-${user}-to-group-${group}":
        command => "usermod -a -G ${group} ${user}",
        unless  => "id ${user} |grep -q ${group}",
    }
}

class util::packages {
    package {['sudo']:
        ensure => installed,
    }
}


class util::generic {
    # tmp mounts
    file { [
            '/mnt/tmp',
            '/mnt/tmp1',
            '/mnt/tmp2',
            '/mnt/tmp3',
            ]:
                ensure => directory,
    }
}


define util::service_disable {
    service { $title:
        enable => false,
        status => "stat -t /etc/rc?.d/S??${title} > /dev/null 2>&1",
    }
}

define util::update_alternatives (
    $target,
) {
    exec { "update-alternatives --set $name $target":
        path   => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
        unless => "/bin/sh -c '[ -L /etc/alternatives/$name ] && [ /etc/alternatives/$name -ef $target ]'",
  }
}


class util::etckeeper {
    package {'etckeeper':
        ensure => installed,
    }
    file {'/etc/cron.daily/etckeeper-cleanup':
        content => template('util/etckeeper-cleanup'),
        mode    => 755,
    }
}
