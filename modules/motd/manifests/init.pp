class motd::init {
}

class motd {
    concat { '/etc/motd':
        mode => "644",
        owner => root,
        order => numeric,
    }
    concat::fragment {'motd-header':
        content => template("motd/header"),
        target  => '/etc/motd',
        order   => '0000',
    }
    # always end motd with newline
    concat::fragment {'motd-newline':
        content => inline_template('<%= "\e[39m\n" %>'),
        target  => '/etc/motd',
        order   => 9999,
    }
}
