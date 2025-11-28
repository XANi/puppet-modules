#!/usr/bin/perl
# puppet managed file, for more info 'puppet-find-resources $filename'


# template for new commandline scripts
use v5.10;
use lib '/usr/local/lib/perl5'; # arte libs
use strict;
use warnings;
use Carp qw(croak cluck carp confess);
use Getopt::Long qw(:config auto_help);
use Net::Domain qw(hostfqdn);
use Pod::Usage;
use LWP::Simple;
use Data::Dumper;
use Arte::Collectd;
use List::Util qw(min max sum);
use JSON qw(decode_json);

my $cfg = { # default config values go here
    'hostname' => hostfqdn(),
    'interval'    => 10,
};
my $help;

GetOptions(
    'interval=s'    => \$cfg->{'interval'},
    'help'          => \$help,
) or pod2usage(
    -verbose => 2,  #2 is "full man page" 1 is usage + options ,0/undef is only usage
    -exitval => 1,   #exit with error code if there is something wrong with arguments so anything depending on exit code fails too
);



# some options are required, display short help if user misses them
my $required_opts = [ ];
my $missing_opts;
foreach (@$required_opts) {
    if (!defined( $cfg->{$_} ) ) {
        push @$missing_opts, $_
    }
}

if ($help || defined( $missing_opts ) ) {
    my $msg;
    my $verbose = 2;
    if (!$help && defined( $missing_opts ) ) {
        $msg = 'Opts ' . join(', ',@$missing_opts) . " are required!\n";
        $verbose = 1; # only short help on bad arguments
    }
    pod2usage(
        -message => $msg,
        -verbose => $verbose, #exit code doesnt work with verbose > 2, it changes to 1
    );
}
my $c = Arte::Collectd->new(
    hostname => $cfg->{'hostname'},
    plugin => 'gpu',
    interval => $cfg->{'interval'},
);
$| = 1; #unbuffer out, important!
open(SMI,'-|','amd-smi metric --json -w 2');
while($c->sleep) {
    my $start=0;
    my $buffer='';
    while(my $line = <SMI>) {
        if ($line =~ /^\[/) {
            $start = 1;
        }
        elsif ($line =~ /^\]/) {
            last;
        }
        elsif ($start == 1) {
            $buffer .= $line;
        }
    }
    my $gpu;
    eval {
        $gpu = decode_json($buffer);
    };
    if (!defined($gpu)) {
        croak($@);
    }
    #print Dumper $gpu;
    my $instance = 'amd-' . $gpu->{'gpu'};
    while (my ($k, $v) = each(%{$gpu->{'temperature'}})) {
        if ($v->{'unit'} ne 'C') {
            croak("unit other than C passed for temp!")
        }
        print $c->generate(
            'plugin-instance' => $instance,
            'value'           => $v->{'value'},
            'type'            => 'temperature',
            'type-instance'   => $k,
        );
    }
    print $c->generate(
        'plugin-instance' => $instance,
        'value' => hash_to_bytes($gpu->{'mem_usage'}{'used_vram'}),
        'type'  => 'bytes',
        'type-instance' => 'used',
    );
    print $c->generate(
        'plugin-instance' => $instance,
        'value' =>  hash_to_bytes($gpu->{'mem_usage'}{'free_vram'}),
        'type'  => 'bytes',
        'type-instance' => 'free',
    );
    if ( $gpu->{'mem_usage'}{'used_gtt'} ) {
        print $c->generate(
            'plugin-instance' => $instance,
            'value' =>  hash_to_bytes($gpu->{'mem_usage'}{'free_vram'}),
            'type'  => 'bytes',
            'type-instance' => 'used_host_gtt',
        );
    }

    print $c->generate(
        'plugin-instance' => $instance,
        'value' => $gpu->{'usage'}{'gfx_activity'}{'value'},
        'type'  => 'percent',
        'type-instance' => 'util_gpu',
    );
    print $c->generate(
        'plugin-instance' => $instance,
        'value' =>  $gpu->{'usage'}{'umc_activity'}{'value'},
        'type'  => 'percent',
        'type-instance' => 'util_mem',
    );
    print $c->generate(
        'plugin-instance' => $instance,
        'value' => $gpu->{'usage'}{'mm_activity'}{'value'},
        'type'  => 'percent',
        'type-instance' => 'util_media',
    );
    print $c->generate(
        'plugin-instance' => $instance,
        'value' => $gpu->{'fan'}{'rpm'},
        'type'  => 'fanspeed',
        'type-instance' => 'main',
    );
    print $c->generate(
        'plugin-instance' => $instance,
        'value' => $gpu->{'fan'}{'usage'}{'value'},
        'type'  => 'percent',
        'type-instance' => 'fan',
    );

    # print $c->generate(
    #     'plugin-instance' => $instance,
    #     'value' => $util_mem_num,
    #     'type'  => 'percent',
    #     'type-instance' => 'util_mem',
    # );

    #$c->sleep();
}

sub to_bytes {
    my $val = shift;

    my ($val_bytes) = $val =~ /(\d+)/;
    if ($val =~ /MiB|MB/i) {
        return $val_bytes * 1024 * 1024
    }
    elsif ($val =~ /KiB|kB/i) {
        return $val_bytes * 1024
    }
    elsif ($val =~ /GiB|GB/i) {
        return $val_bytes * 1024 * 1024 * 1024
    }
    return $val_bytes
}

sub hash_to_bytes {
    my $h = shift;
    return to_bytes( $h->{'value'} . $h->{'unit'}),
}

__END__

=head1 NAME

collectd_bareos.pl - get bacula/bareos status

=head1 SYNOPSIS

collectd_bareos.pl --interval 60

=head1 DESCRIPTION

Run with bareos or bacula or any user that can access bconsole

=head1 OPTIONS

parameters can be shortened if unique, like  --add -> -a

=over 4

=item B<--option1> val2

sets option1 to val2. Default is val1

=item B<--help>

display full help

=back

=head1 EXAMPLES

=over 4

=item B<get_app_stats.pl>

Does foo to bar with defaults

=item B<get_app_stats.pl --bar bar2>

Does foo to specified bar

=back

=cut
