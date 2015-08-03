
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
    $metric = false,
    $mtu = false,
    # ppp options
    $ptp = false,
    # dhcp opts
    $leasetime = false,
    $vendor = false,
    $client = false,
)   {
    require network
    if $title !~ /^[a-zA-Z0-9_-]+$/ {
        fail('Title must match ^[a-zA-Z0-9_-]+$')
    }

    # so we can easily use shortcuts and add/rename/del vars without touching erbs
    $keys = {
        address     => $addr,
        hwaddress   => $hwaddr,
        netmask     => $netmask,
        metric      => $metric,
        mtu         => $mtu,
        pointopoint => $ptp,
        leasetime   => $leasetime,
        vendor      => $vendor,
        client      => $client
    }
    file {"/etc/network/interfaces.d/$title":
        content => template("network/if-debian"),
        mode => 644,
        owner => root,
    }
}
