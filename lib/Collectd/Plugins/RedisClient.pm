package Collectd::Plugins::RedisClient;

use strict;
use warnings;
use Collectd qw( :all );

use Redis;

# ABSTRACT: collectd plugin for reading counters from a redis server
# VERSION

=head1 SYNOPSIS

This is a collectd plugin for reading counters from a redis server.

In your collectd config:

    <LoadPlugin "perl">
    	Globals true
    </LoadPlugin>

    <Plugin "perl">
      BaseName "Collectd::Plugins"
      LoadPlugin "RedisClient"

    	<Plugin "RedisClient">
		prefix "redis"
                metric "sa-timing.*.count" "counter"
                metric "sa-timing.*.time" "counter"
    	</Plugin>
    </Plugin>

=head1 SEE ALSO

L<Mail::SpamAssassin::Plugin::RuleTimingRedis>

=cut

our $prefix = 'redis';
our $server = '127.0.0.1:6379';
our $metrics = { };

our $redis;

sub redis_client_stats_config {
    my ($ci) = @_;
    foreach my $item (@{$ci->{'children'}}) {
        my $key = lc($item->{'key'});
        my $val = $item->{'values'};

        if ($key eq 'server' ) {
            $server = $val->[0];
        } elsif ($key eq 'prefix' ) {
            $prefix = $val->[0];
        } elsif ($key eq 'metric') {
            $metrics->{$val->[0]} = $val->[1];
        }
    }
    return 1;
}

sub _connect_redis {
    if( ! defined $redis ) {
        eval { $redis = Redis->new( 'server' => $server ) };
        if( $@ ) {
            die('could not connect to redis: '.$@);
        }
    }
    return $redis;
}

sub redis_client_stats_read {
    _connect_redis();
    
    foreach my $metric (keys %$metrics) {
        my $type  = $metrics->{$metric};

        my @keys = $redis->keys( $metric );
        if( scalar(@keys) == 0 ) { next; }

        my @values = $redis->mget( @keys );
        for( my $i = 0 ; $i < scalar @keys ; $i++ ) {
            my $vl = {
                plugin => 'redis_client',
                plugin_instance => $prefix,
                type => $type,
                type_instance => $keys[$i],
                values => [ $values[$i] ],
            };
            plugin_dispatch_values($vl);
        }
    }
    return 1;
}

plugin_register(TYPE_CONFIG, "RedisClient", "redis_client_stats_config");
plugin_register(TYPE_READ, "RedisClient", "redis_client_stats_read");

1;

