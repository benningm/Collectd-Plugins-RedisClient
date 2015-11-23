use strict;
use warnings;

use Test::More;
use File::Find;

plan skip_all => "Using Collectd outside of collectd-perl causes strictness errors";

our $count = 0;

find(\&find_cb, './lib');

sub find_cb {
	my $file = $File::Find::name;
	my $package;

	if ($file !~ m/\.pm$/) {
		return;
	}
	$package = $file;
	$package =~ s/^\.\/lib\///;
	$package =~ s/\.pm$//;
	$package =~ s/\//::/g;
	$count++;
	use_ok($package);
}

done_testing($count);

