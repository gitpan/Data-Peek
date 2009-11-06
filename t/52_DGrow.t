#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use Test::NoWarnings;

use Data::Peek qw( DGrow DDump );

my $x = "";
is (length ($x), 0,		"Initial length = 0");
my %dd = DDump $x;
ok ($dd{LEN} <= 16);
ok (my $l = DGrow ($x, 10000),	"Set to 10000");
is (length ($x), 0,		"Variable content");
is ($l, 10000,			"returned LEN");
   %dd = DDump $x;
is ($dd{LEN}, 10000,		"LEN in variable");
is (DGrow (\$x, 20000), 20000,	"Set to 20000");
   %dd = DDump $x;
is ($dd{LEN}, 20000);
is (DGrow ($x, 20),	20000,	"Don't shrink");

1;
