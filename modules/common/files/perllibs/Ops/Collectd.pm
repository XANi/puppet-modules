# puppet managed

package Ops::Collectd;

use strict;
use warnings;
use Carp qw(cluck croak carp);
use Data::Dumper;
use Net::Domain qw(hostfqdn);
use List::Util qw(min max);
require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.01';

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless($self, $class);
    my $cfg;
    # accept both direct hash or reference so
    # new({arg => 1}), new(arg => 1), new($params)
    # work
    if (ref($_[0]) eq 'HASH') {
        $cfg = shift;
    }
    else {
        $cfg = { @_ };
    }
    $cfg->{'hostname'} ||= hostfqdn();
    $cfg->{'interval'} ||= '60';
    $self->{'cfg'} = $cfg;
    # make first call return instantly so it can be used in while($c->sleep())
    $self->{'last_sleep'} = 0;
    $self->{'croak-on-no-data'} ||= 1;
    return $self;
}

sub generate {
    my $self = shift;
    my $arg = { @_ };
    my $out = undef;
    # drop newlines
    while (my($k, $v) = each %$arg) {
        # in case caller passes key => undef
        if (defined($v)) {
            $v =~ s/\n/_/g ;$arg->{$k} = $v;
        }
    };
    $arg->{'hostname'} ||= $self->{'cfg'}{'hostname'};
    $arg->{'plugin'} ||= $self->{'cfg'}{'plugin'};
    $arg->{'plugin-instance'} ||= $self->{'cfg'}{'plugin-instance'};
    $arg->{'interval'} ||= $self->{'cfg'}{'interval'};
    $arg->{'ts'} ||= int(time); # in case someone uses time::hirez that makes that return float
    if (!defined($arg->{'hostname'})) {
        cluck("Hostname not specified");
    }
    if (!defined($arg->{'plugin'})) {
        cluck("Plugin not specified");
    }
    if (!defined($arg->{'type'})) {
        cluck("Type not specified");
    }
    $out .= "PUTVAL \"" . $arg->{'hostname'} . '/';
    if (defined($arg->{'plugin-instance'})) {
        $out .= $arg->{'plugin'} . '-' . $arg->{'plugin-instance'} . '/';
    }
    else {
        $out .= $arg->{'plugin'} . '/';
    }
    if (defined($arg->{'type-instance'})) {
        $out .= $arg->{'type'} . '-' . $arg->{'type-instance'} . '';
    }
    else {
        $out .= $arg->{'type'} . '';
    }
    $out .= "\" interval=$arg->{'interval'} ";
    if (defined($arg->{'ts'})) {
        $out .= $arg->{'ts'} . ':';
    } else {
        croak("No ts: " .Dumper $arg);
    }
    if(!defined($arg->{'value'})) {
        if ($self->{'croak-on-no-data'}) {
            croak("No data:" . Dumper $arg)
        } else {
            return "";
        }
    }
    if (ref($arg->{'value'}) eq "ARRAY") {
        $out .= join(':',@{$arg->{'value'}})
    } else {
        $out .= $arg->{'value'};
    }
    $out .= "\n";
}

sub sleep {
    my $self = shift;
    my $since_last = time() - $self->{'last_sleep'};
    my $sleep = $self->{'cfg'}{'interval'} - $since_last;
    # sanitize sleep time
    $sleep = min( max(1,$sleep) , $self->{'cfg'}{'interval'});
    sleep $sleep;
    $self->{'last_sleep'} = time();
    return 1;
}
sub reset_timer {
    my $self = shift;
    $self->{'last_sleep'} = 0;
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

B<Ops::Collectd> - Generate collectd-formatted data

=head1 CONFIGURATION

no configuration is required, however you can specify defaults on creation time:

* hostname
* plugin
* plugin-instance
* interval (defaults to 60)

if not specified in constructor you need to specify them on generating

additional options:
* croak-on-no-data - defaults to 1, plugin dies when value is undefined. set to 0 to silently not generate output

helpers:

$c->sleep()  - sleep remainder of collectd interval, to be used in while loop:

    while($c->sleep()) {;;}

will sleep only 1s on first iteration

$c->reset_timer - reset sleep timer;

=head1 EXAMPLE

example usage of code

=head1 DESCRIPTION

description
