#!/usr/bin/perl -w
# $Id: test.t,v 1.1 2004/01/30 09:33:25 ianf Exp $

use strict;
use Test;

BEGIN { plan tests => 5 };
use HETZNER::Interpolator;
ok(1);

my %int;
$int{bar} = 'Bar';
my $p = new HETZNER::Interpolator( { filename => 't/foo.int' }, \%int);
ok($p);
my @arr = split('\n', $p);
ok(1) if $arr[2] eq 'Foo';
ok(1) if $arr[3] eq 'Bar';
ok(1) if $arr[6] eq 'Baz';
