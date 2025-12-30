class bird3::client (
    $ip = $ipaddress,
    $asn = lookup("asn::${site}::dist"),
    $ha_ip,
    $export_tag,
) {
    # bird3::config { 'bgp':
    #     config => {
    #         'protocol bgp vm_gw' => [
    #             {"ipv4" => [
    #                 "export none",
    #                 "import all",
    #             ]},
    #             "neighbor $ip as 64807",
    #         ]
    #     }
    # }
    $instance_name =  tr($hostname,'-','_')
    $ip_rules =  flatten([
        flatten([$ha_ip]).map |$p| { "if net = ${p}/32 then accept" },
        'reject'
    ])
    @@bird3::config { "bgp_ha_$hostname":
        config => {
            "protocol bgp ha_${instance_name}" => [
                {"ipv4" => [
                    "export none",
                    {"import filter"=> $ip_rules },
                ]},
                "local as ${asn}",
                "neighbor $ip as ${asn}",
            ]
        },
        tag => $export_tag,
    }
    @@bird::config { "bgp_ha_$hostname":
        config => {
            "protocol bgp ha_${instance_name}" => [
                "export none",
                {"import filter"=> $ip_rules },
                "local as ${asn}",
                "neighbor $ip as ${asn}",
            ]
        },
        tag => $export_tag,
    }
}