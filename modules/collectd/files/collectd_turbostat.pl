#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;
use Carp qw(croak cluck carp confess);
use Getopt::Long qw(:config auto_help);
use Pod::Usage;
use Data::Dumper;
use Net::Domain  qw(hostname hostfqdn hostdomain domainname);;
$ENV{'PATH'}= '/sbin:/bin:/usr/sbin:/usr/bin';
my $cfg = { # default config values go here
};
my $help;
$| = 1;
GetOptions(
    'interval=i'    => \$cfg->{'interval'},
    'help'          => \$help,
) or pod2usage(
    -verbose => 2,  #2 is "full man page" 1 is usage + options ,0/undef is only usage
    -exitval => 1,   #exit with error code if there is something wrong with arguments so anything depending on exit code fails too
);

$cfg->{'collectd-host'} ||= hostfqdn();
$cfg->{'interval'} ||= 10;

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


$| = 1;


open(my $turbostat, '-|',
    'sudo','turbostat', '--quiet', '--show', 'power', '--show', 'topology','--interval',$cfg->{'interval'},
);
while(<$turbostat>) {
    chomp;
    my $t = time;
    my ($core, $cpu,$core_watts,$pkg_watts) = split(/\s+/,$_,4);
    if(!defined($core_watts)) {next}
    if($core_watts !~/^[0-9]/) {next}
    if (defined($pkg_watts) && $core eq '-') {
        say "PUTVAL $cfg->{'collectd-host'}/turbostat-pkg00/power-cores interval=$cfg->{interval} $t:$core_watts";
        say "PUTVAL $cfg->{'collectd-host'}/turbostat-pkg00/power-pkg interval=$cfg->{interval} $t:$pkg_watts";
    } elsif ($core =~/^[0-9]/) {
        say "PUTVAL $cfg->{'collectd-host'}/turbostat-pkg00/power-core_$core interval=$cfg->{interval} $t:$core_watts";
    }
}


__END__

=head1 NAME

collectd_mpower.pl - collect power usage from ubiquitiy mpower


=head1 SYNOPSIS

collectd_mpower.pl --host hostname --user username

=head1 USAGE

This program relies on SSH setup for device

After setting password in panel, do ssh-copy-id user@host to setup your key
