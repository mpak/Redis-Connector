use strict;
use Test::More tests => 3;

use Redis::Connector;

my $CLASS = 'Redis::Connector';
my %ARGS = ( encoding => undef, password => 123 );

isa_ok($CLASS->new(), $CLASS, 'Init with default arguments');
isa_ok($CLASS->new(%ARGS), $CLASS, 'Init with HASH');
isa_ok($CLASS->new(\%ARGS), $CLASS, 'Init with HASHREF');
