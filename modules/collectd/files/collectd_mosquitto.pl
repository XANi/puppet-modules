#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;
use Carp qw(croak cluck carp confess);
use Getopt::Long qw(:config auto_help);
use Pod::Usage;
use Data::Dumper;
use Net::Domain  qw(hostname hostfqdn hostdomain domainname);;

use JSON qw(encode_json);
$ENV{'PATH'}= '/sbin:/bin:/usr/sbin:/usr/bin';
my $cfg = { # default config values go here
    host            => 'localhost',
    user            => 'mqtt',
    pass            => 'mqtt',
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

my $stat_map = {
# $SYS/broker/version mosquitto version 1.5.7
# $SYS/broker/uptime 29315 seconds
    '$SYS/broker/clients/total' => {
        'type'            => 'gauge',
        'type-instance'   => 'total',
        'plugin-instance' => 'clients',
    },
    # '$SYS/broker/clients/inactive' dup of disconnected
    '$SYS/broker/clients/disconnected' => {
        'type'            => 'gauge',
        'type-instance'   => 'disconnected',
        'plugin-instance' => 'clients',
    },
    # '$SYS/broker/clients/active' - dup of connected
    '$SYS/broker/clients/connected' => {
        'type'            => 'gauge',
        'type-instance'   => 'connected',
        'plugin-instance' => 'clients',
    },
    '$SYS/broker/clients/expired' => {
        'type'            => 'gauge',
        'type-instance'   => 'expired',
        'plugin-instance' => 'clients',
    },
    '$SYS/broker/clients/maximum' => {
        'type'            => 'gauge',
        'type-instance'   => 'maximum',
        'plugin-instance' => 'clients',
    },
    # $SYS/broker/load/messages/received/1min 4.08
    # $SYS/broker/load/messages/received/5min 1.45
    # $SYS/broker/load/messages/received/15min 0.68
    # $SYS/broker/load/messages/sent/1min 188.47
    # $SYS/broker/load/messages/sent/5min 71.29
    # $SYS/broker/load/messages/sent/15min 30.16
    # $SYS/broker/load/publish/dropped/1min 0.00
    # $SYS/broker/load/publish/dropped/5min 0.00
    # $SYS/broker/load/publish/dropped/15min 0.00
    # $SYS/broker/load/publish/received/1min 0.00
    # $SYS/broker/load/publish/received/5min 0.00
    # $SYS/broker/load/publish/received/15min 0.00
    # $SYS/broker/load/publish/sent/1min 184.39
    # $SYS/broker/load/publish/sent/5min 69.84
    # $SYS/broker/load/publish/sent/15min 29.48
    # $SYS/broker/load/bytes/received/1min 106.52
    # $SYS/broker/load/bytes/received/5min 38.05
    # $SYS/broker/load/bytes/received/15min 18.43
    # $SYS/broker/load/bytes/sent/1min 7494.70
    # $SYS/broker/load/bytes/sent/5min 2833.09
    # $SYS/broker/load/bytes/sent/15min 1192.82
    # $SYS/broker/load/sockets/1min 1.82
    # $SYS/broker/load/sockets/5min 0.64
    # $SYS/broker/load/sockets/15min 0.31
    # $SYS/broker/load/connections/1min 1.82
    # $SYS/broker/load/connections/5min 0.64
    # $SYS/broker/load/connections/15min 0.31'
    '$SYS/broker/messages/stored' => {
        'type'            => 'gauge',
        'type-instance'   => 'stored',
        'plugin-instance' => 'messages',
    },
    '$SYS/broker/messages/received' => {
        'type'            => 'derive',
        'type-instance'   => 'received',
        'plugin-instance' => 'messages',
    },
    '$SYS/broker/messages/sent' => {
        'type'            => 'derive',
        'type-instance'   => 'sent',
        'plugin-instance' => 'messages',
    },
    '$SYS/broker/messages/inflight' => {
        'type'              => 'gauge',
        'type-instance'     => 'inflight',
        'plugin-instance'   => 'messages',
        'emit-0-if-missing' => 1,
    },
    '$SYS/broker/store/messages/count' => {
        'type'            => 'gauge',
        'type-instance'   => 'stored',
        'plugin-instance' => 'messages_store',

    },
    '$SYS/broker/store/messages/bytes' => {
        'type'            => 'bytes',
        'type-instance'   => 'stored',
        'plugin-instance' => 'messages_store',
    },
    '$SYS/broker/subscriptions/count' => {
        'type'            => 'gauge',
        'type-instance'   => 'subscriptions',
        'plugin-instance' => 'broker',
    },
    '$SYS/broker/retained messages/count' => {
        'type'            => 'gauge',
        'type-instance'   => 'retained_messages',
        'plugin-instance' => 'broker',
    },
    '$SYS/broker/heap/current' => {
        'type'            => 'bytes',
        'type-instance'   => 'current',
        'plugin-instance' => 'heap',
    },
    '$SYS/broker/heap/maximum' => {
        'type'            => 'bytes',
        'type-instance'   => 'max',
        'plugin-instance' => 'heap',
    },
    '$SYS/broker/publish/messages/received' => {
        'type'            => 'derive',
        'type-instance'   => 'received',
        'plugin-instance' => 'messages_publish',
    },
    '$SYS/broker/publish/messages/sent' => {
        'type'            => 'derive',
        'type-instance'   => 'sent',
        'plugin-instance' => 'messages_publish',
    },
    '$SYS/broker/publish/messages/sent' => {
        'type'            => 'derive',
        'type-instance'   => 'dropped',
        'plugin-instance' => 'messages_publish',
    },
    '$SYS/broker/publish/bytes/received' => {
        'type'            => 'total_bytes',
        'type-instance'   => 'received',
        'plugin-instance' => 'messages_publish',
    },
    '$SYS/broker/publish/bytes/sent' => {
        'type'            => 'total_bytes',
        'type-instance'   => 'sent',
        'plugin-instance' => 'messages_publish',

    },
    '$SYS/broker/bytes/received' => {
        'type'            => 'total_bytes',
        'type-instance'   => 'received',
        'plugin-instance' => 'broker',
    },
    '$SYS/broker/bytes/sent' => {
        'type'            => 'total_bytes',
        'type-instance'   => 'sent',
        'plugin-instance' => 'broker',
    },
};

open(my $mosquitto, '-|',
    'mosquitto_sub','-W','25', '-v', '-h', $cfg->{'host'}, '-t', '$SYS/#', '-u', $cfg->{'user'}, '-P', $cfg->{'pass'},
);
while(<$mosquitto>) {
    chomp;
    my ($k, $v) = split(/ /,$_,2);
    my $t = time;
    if (defined ($stat_map->{$k})) {
        my $s =  $stat_map->{$k};
        print "PUTVAL $cfg->{'collectd-host'}/mosquitto-$s->{'plugin-instance'}/$s->{'type'}-$s->{'type-instance'} interval=60 $t:$v\n";
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
