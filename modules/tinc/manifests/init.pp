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
    exec {"${module::name}::${network}::generate_key":
        command => "tinc -K -n ${network}",
        creates => "/etc/tinc/${network}/rsa_key.priv",
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

define tinc::pubkey($key, $network,$address=false) {
    if $address {
        file {"/etc/tinc/${network}/hosts/${title}":
            content => "Address = ${address}\n${key}\n"
        }
    } else {
        file {"/etc/tinc/${network}/hosts/${title}":
            content => "${key}\n"
        }
    }
}
