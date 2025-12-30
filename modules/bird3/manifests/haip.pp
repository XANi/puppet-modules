class bird3::haip (
    $peer_ip = $service_gw,
    $router_id = $ipaddress,
    $self_ip = $ipaddress,
    $asn = lookup("asn::${site}::dist"),
    $ospf_interface = false,
    $external_upstream_config = false,
    $ha_ip,
){
    class { 'bird3':
        router_id => $ipaddress,
    }
    $ip_rules =  flatten([
        flatten([$ha_ip]).map |$p| { "if net = ${p}/32 then accept" },
        'reject'
    ])
    bird3::config { 'filter-ha_ip':
        config => {
            'filter ha_ip' => $ip_rules,
        }
    }
    bird3::config { 'kernel':
        config => {
            'protocol kernel' => [
                "merge paths on limit 4",
                {'ipv4' => [
                    "import filter ha_ip",
                    "export filter ha_ip"
                ], },
                "learn",
            ],
        }
    }
    bird3::config { 'direct':
        config => {
            'protocol direct' => [
                'ipv4'
            ]
        }
    }
    if $external_upstream_config {
    }
    elsif $ospf_interface {
        bird3::config { 'ospf-dist':
            config => {
                'protocol ospf haip' => [
                    'stub router',
                    'ecmp',
                    'merge external',
                    { 'ipv4' => [
                        'import filter ha_ip',
                        'export filter ha_ip',
                    ] }, # FIXME
                    { 'area 0' => {
                        'interface "lo"'                  => [ 'stub' ],
                        "interface \"${ospf_interface}\"" => [  ],
                    } },
                ]
            }
        }
    } elsif $peer_ip {
        bird3::config { 'bgp':
            config => {
                'protocol bgp vm_gw' => [
                    { "ipv4" => [
                        "export filter ha_ip",
                        "import none",
                    ] },
                    # "advertise hostname",
                    "local ${self_ip} as ${asn}",
                    "neighbor ${peer_ip} as ${asn}",
                ]
            }
        }
    } else {
        fail("either peer_ip or ospf is required")
    }


}
