
define network::if (
    $ifname = $title,
    $type = "inet",
    $method = "static",
    $boot = true,
    $hotplug = true,
    $addr = false,
    $hwaddr = false,
    $netmask = false,# rarely needed, you shoudl use CIDR for visibility
    $broadcast = false, # let OS figure it out
    $gateway = false,
    $metric = false,
    $mtu = false,
    # ppp options
    $ptp = false,
    # dhcp opts
    $leasetime = false,
    $vendor = false,
    $client = false,
    $dhcp_hostname = false,
)   {
    require network
    $filename = regsubst($title,'[^a-zA-Z0-9_-]{1}','_','G')

    # so we can easily use shortcuts and add/rename/del vars without touching erbs
    $keys = {
        address     => $addr,
        hwaddress   => $hwaddr,
        netmask     => $netmask,
        gateway     => $gateway,
        metric      => $metric,
        mtu         => $mtu,
        pointopoint => $ptp,
        leasetime   => $leasetime,
        vendor      => $vendor,
        client      => $client,
        hostname    => $dhcp_hostname,
    }
    file {"/etc/network/interfaces.d/$filename":
        content => template("network/if-debian"),
        mode => "644",
        owner => root,
    }
}
