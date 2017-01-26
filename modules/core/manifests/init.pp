class core::desktop {
    include core::apt::base
}

class core::server {
    include core::apt::base
    apt::conf {"no-suggested":
        content => 'APT::Install-Suggests "0";'
    }
}

class core {
    include core::apt::base
    notify {"Please use core::server or core::desktop":;}
}

class core::apt::base {
    create_resources("@apt::source",hiera('repos'))
    file {'/etc/apt/apt.conf.d/99-zpuppet.conf':
        ensure => absent,
    }

}
