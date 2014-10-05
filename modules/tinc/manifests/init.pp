class tinc  {
    package {tinc:
        ensure => installed;
    }
    $config = hiera('tinc')
}

define tinc::net($network=$title) {
    file {"/etc/tinc/${network}":
        ensure => directory;
    }
    tinc::deploy_keys {$network:;}
}

define tinc::deploy_keys($network=$title) {
    require tinc

    $tinc_config = $tinc::config

    file {"/etc/tinc/${network}/hosts":
        ensure => directory;
    }
    Tinc::Pubkey {
        network => $network,
    }
    create_resources('tinc::pubkey',$tinc_config['networks'][$network]['keys'])
}

define tinc::pubkey($key, $network) {
    file {"/etc/tinc/${network}/hosts/${title}":
        content => $key
    }
}
