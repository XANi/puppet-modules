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
    'interval'    => 60,
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
    plugin => 'template',
    interval => $cfg->{'interval'},
);
$| = 1; #unbuffer out, important!
while($c->sleep) {
    open(BUCKETS,'-|','/usr/local/bin/garage','json-api','ListBuckets');
    my $b_raw;
    {
        local $/;
        $b_raw = <BUCKETS>;
    }
    close(BUCKETS);
    my $b_list;
    eval {
        $b_list = decode_json($b_raw);
    };
    if (!defined($b_list)) {
        carp($@);
        next;
    }
    for my $bu (@{$b_list}) {
        for my $v (@{$bu->{'globalAliases'}}) {
            open(B,'-|','/usr/local/bin/garage',
                'json-api',
                'GetBucketInfo',
                "{\"globalAlias\":\"$v\"}",
            );
                  my $b_info_raw;
            {
                local $/;
                $b_info_raw = <B>;
            }
            close(B);
            my $b_info;
            eval {
                $b_info = decode_json($b_info_raw);
            };
            print $c->generate(
                'plugin-instance' => 'buckets',
                'value' =>  $b_info->{'bytes'},
                'type'  => 'bytes',
                'type-instance' => $v,
            );
            print $c->generate(
                'plugin-instance' => 'buckets',
                'value' =>  $b_info->{'objects'},
                'type'  => 'objects',
                'type-instance' => $v,
            );
        }
    }

    #print Dumper $b_list;

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
