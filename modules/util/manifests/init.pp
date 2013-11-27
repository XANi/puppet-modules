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
    exec {"util::update_alternatives ${title}":
        command   => "update-alternatives --set ${title} ${target}",
        unless    => "test $(readlink /etc/alternatives/${title}) == \"${target}\"",
        logoutput => true,
    }
}
