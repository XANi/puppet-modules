package Collectd::Plugins::PSI;

use v5.24;
use strict;
use warnings;
use Collectd qw( :all );


sub psi_data {
   my $f = shift;
   open(F,'<',"/proc/pressure/$f") or die("can't open pressure file");
   my $data = {};
   while(<F>) {
     chomp;
     if ($_ =~ /^some.*avg10=([\.\d]+).*total=(\d+)/) {
         $data->{'some'} ={
           "avg10" => $1,
           "total" => $2,
         };
     }
     if ($_ =~ /^full.*avg10=([\.\d]+).*total=(\d+)/) {
         $data->{'full'} ={
           "avg10" => $1,
           "total" => $2
          };
     }
  }
   return $data;
}
sub psi_read {
    my $type = shift;
    my $data = psi_data($type);
    if ($data->{'some'}) {
        plugin_dispatch_values {
            values              => [ $data->{'some'}{'avg10'} ],
                # interval => plugin_get_interval(),
                # host => "localhost",
                plugin          => "kernel_psi",
                type            => "gauge",
                type_instance   => 'some-avg',
                plugin_instance => $type,
        };
        plugin_dispatch_values {
            values              => [ $data->{'some'}{'total'} ],
                # interval => plugin_get_interval(),
                # host => "localhost",
                plugin          => "kernel_psi",
                type            => "counter",
                type_instance   => 'some-rate',
                plugin_instance => $type,
        };
    }
    if ($data->{'full'}) {
        plugin_dispatch_values {
            values              => [ $data->{'full'}{'avg10'} ],
                # interval => plugin_get_interval(),
                # host => "localhost",
                plugin          => "kernel_psi",
                type            => "gauge",
                type_instance   => 'full-avg',
                plugin_instance => $type,
        };
        plugin_dispatch_values {
            values              => [ $data->{'full'}{'total'} ],
                # interval => plugin_get_interval(),
                # host => "localhost",
                plugin          => "kernel_psi",
                type            => "counter",
                type_instance   => 'full-rate',
                plugin_instance => $type,
        };
    }

    return 1;
}

sub cpu_psi_read {
    return(psi_read('cpu'));
}
sub io_psi_read {
    return(psi_read('io'));
}
sub memory_psi_read {
    return(psi_read('memory'));
}

plugin_register (TYPE_READ, "kernel_psi_cpu", "cpu_psi_read");
plugin_register (TYPE_READ, "kernel_psi_io", "io_psi_read");
plugin_register (TYPE_READ, "kernel_psi_memory", "memory_psi_read");
