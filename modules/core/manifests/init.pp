class core {
    include core::apt::base
}

class core::apt::base {
    create_resources("@apt::source",hiera('repos'))
    file {'/etc/apt/apt.conf.d/99-zpuppet.conf':
        ensure => absent,
    }
    apt::conf {"no-suggested":
        content => 'APT::Install-Suggests "0";'
    }
}
