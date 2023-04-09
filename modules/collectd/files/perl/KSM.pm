package Collectd::Plugins::KSM;

use v5.24;
use strict;
use warnings;
use Collectd qw( :all );
sub read_file {
    my $file = shift;
    open (FH, '<', $file);
    return  do { local $/; <FH> }
}
my $page_size = 4096;


sub ksm_read {
    if ( -e '/sys/kernel/mm/ksm/pages_sharing') {
        my $data = read_file('/sys/kernel/mm/ksm/pages_sharing');
        chomp($data);
        plugin_dispatch_values {
            values              => [ $data * $page_size ],
                # interval => plugin_get_interval(),
                # host => "localhost",
                plugin          => "ksm",
                type            => "bytes",
                type_instance   => 'sharing',
        };
    }
    if ( -e '/sys/kernel/mm/ksm/pages_volatile') {
        my $data = read_file('/sys/kernel/mm/ksm/pages_volatile');
        chomp($data);
        plugin_dispatch_values {
            values              => [ $data * $page_size ],
                # interval => plugin_get_interval(),
                # host => "localhost",
                plugin          => "ksm",
                type            => "bytes",
                type_instance   => 'volatile',
        };
    }
    return 1;
}


plugin_register (TYPE_READ, "kernel_ksm", "ksm_read");
