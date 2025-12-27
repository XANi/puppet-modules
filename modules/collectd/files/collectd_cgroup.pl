#!/usr/bin/perl
use v5.24;
use strict;
use warnings;
use Sys::Hostname;
use Data::Dumper;
my $host = hostname . '.home.zxz.li';


my $cgroup_dir='/sys/fs/cgroup';
my $cgroup_update_every=60;

# first, find cgroups
sub get_cgroups {
    open(F, '-|', "find $cgroup_dir -type d");
    my @cgroup_list;
    while(<F>) {
	chomp;
	push @cgroup_list, $_;
    }
    close(F);
    return \@cgroup_list;
}
my $cgroup_update=0;
my $last_run=scalar time();
my $cgroups;
my $interval;


my $cpu_type = {
    'usage_usec'     => 'cpu',
    'user_usec'      => 'cpu',
    'system_usec'    => 'cpu',
    'throttled_usec' => 'cpu',
    'nr_throttled'   => 'counter',
};

my $memory_type = {
    'anon' => 'bytes',
    'file' => 'bytes',
    'kernel_stack' => 'bytes',
    'sock' => 'bytes',
    'shmem' => 'bytes',
    'file_mapped' => 'bytes',
    'file_dirty' => 'bytes',
    'file_writeback' => 'bytes',
    'inactive_anon' => 'bytes',
    'active_anon' => 'bytes',
    'inactive_file' => 'bytes',
    'active_file' => 'bytes',
    'slab' => 'bytes',
    'slab_reclaimable' => 'bytes',
    'slab_unreclaimable' => 'bytes',
    'pgfault' => 'counter',
    'pgmajfault' => 'bytes',
    'unevictable' => 'bytes',
    'pagetables' => 'bytes',
};

while(sleep 10) {
    $interval = time - $last_run;
    $last_run = time;
    if ( (scalar time() - $cgroup_update) > $cgroup_update_every) {
	$cgroups = &get_cgroups();
    }
    if( defined($cgroups) ) {
	foreach(@$cgroups) {
	    my $dir = $_;
	    my ($name) = $_ =~ /^.*\/(.+?)$/;
	    if($name eq 'cgroup') {
		$name = 'total';
	    }
	    if ($dir !~ /\.service/) {next;}
        if ($dir =~ /ifup.*service/) {next;}
	    # if ($dir !~ /\.service|slice/) {next;}	
	    &get_stats($dir, $name);
        #say $_;
	}
    }
};


sub parse_cpu_group {
    my $cgroup_name = shift;
    my $fd = shift;
    while (<$fd>) {
        chomp();
        my($key,$val) = split();
        my $type = $cpu_type->{$key};
        if (defined($type) && $val >= 0) {
            printval($cgroup_name, "cpu_$key", $type,$val);
        }
    }
}
sub parse_memory_group {
    my $cgroup_name = shift;
    my $fd = shift;
    while (<$fd>) {
        chomp();
        my($key,$val) = split();
        my $type = $memory_type->{$key};
        if (defined($type) && $val >= 0) {
            printval($cgroup_name, "mem_$key", $type,$val);
        }
    }
}

sub parse_io_group {
    my $cgroup_name = shift;
    my $fd = shift;
    my $stats={};
    while (<$fd>) {
        chomp();
        my @keys = split;
        foreach my $kv (@keys) {
            my ($k, $v) = split(/=/, $kv);
            if (!defined($v)) {next}
            $stats->{$k} += $v;
        }
    }
    printval($cgroup_name, "io_read", 'disk_ops_complex',$stats->{'rios'});
    printval($cgroup_name, "io_write", 'disk_ops_complex',$stats->{'wios'});
    printval($cgroup_name, "io_read", 'total_bytes',$stats->{'rbytes'});
    printval($cgroup_name, "io_write", 'total_bytes',$stats->{'wbytes'});
}



sub get_stats {
    my $dir = shift;
    my $cgroup = shift;

    if ( open(my $f, '<', "$dir/cpu.stat") ) {
        parse_cpu_group($cgroup,$f);
        close($f);
    }
    if ( open(my $f, '<', "$dir/memory.stat") ) {
        parse_memory_group($cgroup,$f);
        close($f);
    }
    if ( open(my $f, '<', "$dir/io.stat") ) {
        parse_io_group($cgroup,$f);
        close($f);
    }
    if ( open(my $f, '<', "$dir/memory.current") ) {
        my $val = <$f>;
        chomp($val);
        &printval($cgroup, 'mem_used', 'bytes', $val);
        close($f);
    }

}

sub printval {
    my $cgroup = shift;
    my $name = shift;
    my $type = shift;
    my $val  = shift;
    if (!defined($val)) {return}
    if ($val==0) {return}
    my $t = scalar time;
    print "PUTVAL $host/cgroup-$cgroup/$type-$name interval=$interval $t:$val\n";
}
