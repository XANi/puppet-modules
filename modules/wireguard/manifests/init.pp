class wireguard::common {
    stdlib::ensure_packages(['wireguard','wireguard-tools','resolvconf'])
}

define wireguard::tunnel (
    $address,
    $private_key,
    $preshared_key = false,
    $listen_port = false,
    $fw_mark = false,
) {
    require wireguard::common
    concat { "/etc/wireguard/${title}.conf":
        owner => 'root',
        mode  => '600',
    }
    concat::fragment { "wireguard::${title}::head":
        target => "/etc/wireguard/${title}.conf",
        order   => 0,
        content => template('wireguard/wireguard-base.conf'),
    }


}

define wireguard::peer (
    $tunnel,
    $public_key,
    $preshared_key = false,
    $endpoint = false,
    Variant[Boolean[false],Integer[0,65535]] $keepalive = false,
    Array $allowed_ips = []
) {
    concat::fragment { "wireguard::${tunnel}::${title}":
        target => "/etc/wireguard/${tunnel}.conf",
        order   => 1,
        content => template('wireguard/wireguard-peer.conf'),
    }

}

class wireguard::keyshare(Array $vpn_nodes) {
    if $networking['hostname'] in $vpn_nodes {
        stdlib::ensure_packages(['wireguard','wireguard-tools'])
        $vpn_nodes.each |$n| {
            $wg_key = "@wireguard::${n}::pub"
            $pubk = messdb_read($wg_key)
            if $pubk {
                file { "/tmp/key_${n}":
                    content => $pubk
                }
            }
            if $n == $networking['hostname'] {
                $privk = messdb_read("wireguard::${n}::keypair")
                if $pubk == undef or $privk == undef {
                    notify { "key for $n not generated":; }
                    $keydata = generate_ed25519_keypair()
                    if $keydata {
                        messdb_write($wg_key,$keydata['pub'])
                        messdb_write("wireguard::${n}::keypair",$keydata)
                    } else {
                        notify { "key generation not worked":; }
                    }
                }
            }
        }
    } else {
        fail("my node is not in ${vpn_nodes}")
    }
}