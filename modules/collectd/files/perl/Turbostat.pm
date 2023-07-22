package Collectd::Plugins::Turbostat;

use v5.24;
use strict;
use warnings;
use Collectd qw( :all );


sub p {
    #plugin_dispatch_values {
    #    values              => [ $data->{'some'}{'total'} ],
    #        # interval => plugin_get_interval(),
    #        # host => "localhost",
    #        plugin          => "kernel_psi",
    #        type            => "counter",
    #        type_instance   => 'some-rate',
    #        plugin_instance => $type,
    #};
    return 1;
}


# plugin_register (TYPE_READ, "kernel_psi_cpu", "cpu_psi_read");