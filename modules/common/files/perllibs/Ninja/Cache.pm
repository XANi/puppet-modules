package Ninja::Cache;


our $VERSION = '0.01';

use strict;
use warnings;
use DBI;
use DBD::SQLite;
use File::Basename;
use version;
use Storable qw(thaw freeze);
use Carp qw(croak cluck carp confess);
use Data::Dumper;
use YAML;
our $query = {
    add => q{INSERT OR REPLACE INTO kv(key, value, ts , ttl, expiry) VALUES(?, ?, strftime('%s', 'now'), ?, ?)},
    del => q{DELETE FROM kv WHERE key = ?},
    get => q{SELECT value, ts, ttl, expiry from kv WHERE key=?},
};

# ninjaed from Log::Any
sub import {
    my $class  = shift;
    my $caller = caller();

    my @export_params = ( $caller, @_ );
    $class->_export_to_caller(@export_params);
}

sub _export_to_caller {
    my $class  = shift;
    my $caller = shift;

    # Parse parameters passed to 'use Log::Any'
    #
    my @vars;
    foreach my $param (@_) {
        if ( $param eq '$cache' ) {
            my $cache = $class->new();
            no strict 'refs';
            my $varname = "$caller\::cache";
            *$varname = \$cache;
        }
        else {
            die "invalid import '$param' - valid imports are '\$cache'";
        }
    }
}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless($self, $class);
    my $cfg = { @_ };
    if (! $cfg->{'path'} ) {
        my $file = ( $cfg->{'name'} || $self->_get_parsed_progname() ) . '.sqlite';
        my $dir  = $self->_generate_dir();
        $cfg->{'path'} = "$dir/$file";
    }
    my $create_db = 0;
    $cfg->{'dbh'} = DBI->connect("dbi:SQLite:$cfg->{'path'}","","") or croak("DBI connection failed: $DBI::errstr");
    # hack around c5 fucked up version
    if($^V gt 'v5.10' && version->parse(($cfg->{'dbh'}->{'sqlite_version'})) > version->parse('3.7.0')) {
        $cfg->{'wal'} ||= 1;
    } else {
        $cfg->{'wal'} = 0;
    }
    $self->{'cfg'} = $cfg;
    $self->_create_or_update_db;
    if (rand(1000) < 1) {
        $self->gc();
    }
    return $self
};

sub set {
    my $self = shift;
    my $key = shift;
    my $value = shift;
    my $ttl = shift;
    $self->{'q'}{'add'} ||= $self->{'cfg'}{'dbh'}->prepare($query->{'add'});
    my $record_ttl = 0;
    my $record_expiry = 0;
    if ($ttl) {
        # intify in case user passes some crap
        $record_ttl = int($ttl);
        $record_expiry = int(time() +  $ttl);
    }
    my $return = undef;
    # if called in non-void content, return previous value
    if (defined wantarray()) {
        $return = $self->get($key);
    }
#    my $serialized;
#    print Dumper $value;
#    print Dump $value;
    my $val;
    $val = \$value;
    $self->{'q'}{'add'}->execute($key, freeze($val), $record_ttl, $record_expiry);
    return $return;
}

sub get {
    my $self = shift;
    my $key = shift;
    my $ttl_offset = shift || 0; # if you want to check if for example "data expires in 5 minutes"
    $self->{'q'}{'get'} ||= $self->{'cfg'}{'dbh'}->prepare($query->{'get'});
    $self->{'q'}{'get'}->execute($key);
    my $data = $self->{'q'}{'get'}->fetchrow_hashref();
    if (!defined($data)) {
        return
    }
    if ($self->_check_ts($data->{'ts'}, $data->{'ttl'} + $ttl_offset , $data->{'expiry'} + $ttl_offset)) {
        $data = thaw($data->{'value'});
        return  $$data
    } elsif ($data->{'expiry'} + 86400 < time()) {
        $self->delete($key);
        return;
    } else {
        return;
    }
}

sub delete {
    my $self = shift;
    my $key = shift;
    my $return = undef;
    $self->{'q'}{'del'} ||= $self->{'cfg'}{'dbh'}->prepare($query->{'del'});
    # if called in non-void content, return previous value
    if (defined wantarray()) {
        $return = $self->get($key);
    }
    $self->{'q'}{'del'}->execute($key);
    return $return;
}

sub get_ttl {
    my $self = shift;
    my $key = shift;
    $self->{'q'}{'get'} ||= $self->{'cfg'}{'dbh'}->prepare($query->{'get'});
    $self->{'q'}{'get'}->execute($key);
    my $data = $self->{'q'}{'get'}->fetchrow_hashref();
    if (!defined($data)) {
        return
    }
    my $t = time;
    if($data->{'expiry'} >= $t) {
        return $data->{'expiry'} - $t;
    } else {
        return
    }
}


sub _create_or_update_db {
    my $self = shift;
    my $dbh = $self->{'cfg'}{'dbh'};
    my $check_meta = $dbh->prepare("SELECT count(*) FROM sqlite_master WHERE type='table' AND name='meta'");
    $check_meta->execute();
    if (scalar $check_meta->fetchrow_array  < 1 ) {
        # drop in case we stumble upon not fully created db or someone messed around with it manually
        $dbh->do(q{DROP TABLE IF EXISTS kv});
        $dbh->do(q{
            CREATE TABLE meta (
                key TEXT UNIQUE,
                value BLOB
            )
        });
        $dbh->do(q{INSERT INTO meta(key,value) VALUES('version','1')});
        print "created meta table\n" if $self->{'cfg'}{'debug'};
        if ($self->{'cfg'}{'wal'}) {
            $dbh->do("PRAGMA journal_mode=WAL");
        }

    }

    my $check_kv = $dbh->prepare("SELECT count(*) FROM sqlite_master WHERE type='table' AND name='kv'");
    $check_kv->execute;
    if (scalar $check_kv->fetchrow_array  < 1 ) {
        # use both relative and absolute TTL so we can detect if record is invalid because system time changed drastically
        my $add_kv = $dbh->do(q{
            CREATE TABLE kv (
                key TEXT UNIQUE NOT NULL,
                value BLOB,
                ts INTEGER,
                ttl INTEGER,
                expiry INTEGER
            )
        });
        print "created kv table\n" if $self->{'cfg'}{'debug'};
    }
}


sub _get_parsed_progname {
    my $self = shift;
    my $name = basename($0);
    $name =~ s{[\/\\\s]}{_}gi;
    return $name;
}
sub _generate_dir {
    my $self = shift;
    my $base = '/var/cache/ninja';
    if ( ! -e $base ) {
        mkdir($base);
        chmod(oct("1777"), $base);
    }
    my $user = (getpwuid($<))[0];
    my $userdir = "$base/$user";
    if ( ! -e $userdir) {
        mkdir($userdir);
        chmod(oct("0700"), $userdir);
    }
    # sanity check
    if ( -d $userdir && -w $userdir && -x $userdir) {
        return $userdir;
    } else {
        $userdir = "/tmp/$user.cache";
        print STDERR "can't access $userdir, will use $userdir !" if $self->{'cfg'}{'debug'};
        mkdir($userdir);
        chmod(oct("0700"), $userdir) or croak($!);
        return $userdir;
    }
}

sub _check_ts {
    my $self = shift;
    my $ts = shift;
    my $ttl = shift;
    my $expiry = shift;
    if ($expiry <= 0 && $ttl <= 0) {
        # no ttl so always valid
        return 1
    }
    # invalid state
    if ($expiry <= 0 xor $ttl <= 0) {
        carp("Bad record, both ttl or expiry should be set or both should be zero!");
        return 0
    }
    if($ts <=0) {
        carp("timestamp has to be positive!");
        return 0;
    }
    if ($ts > $expiry) {
        carp("Record expired before it was created. WTF?");
        return 1;
    }
    if ($ts > time() + 1 || (($expiry - $ttl) > time() + 1)) {
        carp("Record created in the future!");
        return 0;
    }
    # expired records
    if (time() > $expiry) {
        return 0;
    }


    return 1;
}

sub gc {
    my $self = shift;
    $self->{'cfg'}{'dbh'}->do(q{DELETE from kv WHERE expiry < strftime('%s', 'now')});
}


1;
__END__

=head1 NAME

Ninja::Cache - configurationless cache

=head1 SYNOPSIS

  use Ninja::Cache qw($cache);
  $cache->set('var',$content);
  $cache->set('var',$content, 86400);
  $cache->get('var'),
  $cache->delete('var'),


=head1 DESCRIPTION

=over

=item B<$cache->set($key, $value, $ttl)>

set value. If called in non-void context, it will return previous value if it exist

=item B<$cache->get($key,[$offset])>

get value. Offset can be used to modify TTL if you for example want to get value only if it has at least 5 minutes till it will expire

=item B<$cache->delete($key)>

delete value. If called in non-void context, will return deleted value

=item B<$cache->get_ttl($key)>

get remaining TTL of key


=item B<$cache->gc()>

run gc (expiring items mostly)

Not needed under normal operation, it will be run automatically every few thousand ops

=back

It can also be used as object:

my $cache = Ninja::Cache->new(
     path => '/dbi/file/sqlite',
);

my $ = Ninja::Cache->new(
     name => 'cache-shared-across-scripts',
);

=head2 EXPORT

None by default, $cache is object with default config

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

xani, E<lt>xani@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by xani

This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself, either Perl version 5.12.3 or,
  at your option, any later version of Perl 5 you may have available.


=cut
