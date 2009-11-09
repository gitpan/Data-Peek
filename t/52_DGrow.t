#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 15;
use Test::NoWarnings;

use Data::Peek qw( DGrow DDump );

my $x = "";
is (length ($x), 0,		"Initial length = 0");
my %dd = DDump $x;
ok ($dd{LEN} <= 16);
ok (my $l = DGrow ($x, 10000),	"Set to 10000");
is (length ($x), 0,		"Variable content");
ok ($l >= 10000,		"returned LEN >= 10000");
ok ($l <= 10240,		"returned LEN <= 10240");
   %dd = DDump $x;
ok ($dd{LEN} >= 10000,		"LEN in variable >= 10000");
ok ($dd{LEN} <= 10240,		"LEN in variable <= 10240");
ok ($l = DGrow (\$x, 20000),	"Set to 20000");
ok ($l >= 20000,		"LEN in variable >= 20000");
ok ($l <= 20480,		"LEN in variable <= 20480");
   %dd = DDump $x;
ok ($dd{LEN} >= 20000,		"LEN in variable >= 20000");
ok ($dd{LEN} <= 20480,		"LEN in variable <= 20480");
is (DGrow ($x, 20), $l,		"Don't shrink");

1;
