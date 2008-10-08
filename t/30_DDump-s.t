#!/usr/bin/perl

use strict;
use warnings;

# I would like more tests, but contents change over every perl version
use Test::More tests => 6;

use Data::Peek;

$Data::Peek::has_perlio = $Data::Peek::has_perlio = 0;

ok (1, "DDump () NOT using PerlIO");

my @tests;
{   local $/ = "==\n";
    chomp (@tests = <DATA>);
    }

# Determine what newlines this perl generates in sv_peek
my @nl = ("\\n", "\\n");
{   if ($] >= 5.008) {
	my $nl = "\n\x{20ac}";
	chop $nl;
	$nl = DPeek ($nl);
	@nl = ($nl =~ m/"([^"]+)".*"([^"]+)"/);
	}
    ok (1, "This perl dumps \\n as (@nl)");
    }

my $var = "";

foreach my $test (@tests) {
    my ($in, $out) = split m/\n--\n/ => $test;
    $in eq "" and next;
    SKIP: {
	$in =~ m/20ac/ and $] < 5.008 and skip "No UTF8 in ancient perl", 1;

	eval "\$var = $in;";
	my $dump = DDump ($var);
	$dump =~ s/\b0x[0-9a-f]+\b/0x****/g;
	$dump =~ s/\b(REFCNT =) [0-9]{4,}/$1 -1/g;
	# Catch differences in \n
	$dump =~ s/"ab\Q$nl[0]\E(.*?)"ab\Q$nl[1]\E/"ab\\n$1"ab\\n/;

	$dump =~ s/\bLEN = [1-7]\b/LEN = 8/;	# aligned at long long?

	$dump =~ s/\bPADBUSY\b,?//g	if $] < 5.010;

	$dump =~ s/\bUV = /IV = /g	if $] < 5.008;
	$dump =~ s/,?\bIsUV\b//g	if $] < 5.008;

	$in =~ s/[\s\n]+/ /g;
	is ($dump, $out, "DDump ($in)");
	}
    }

1;

__END__
undef
--
SV = PV(0x****) at 0x****
  REFCNT = 1
  FLAGS = (PADMY)
  PV = 0
==
0
--
SV = PVIV(0x****) at 0x****
  REFCNT = 1
  FLAGS = (PADMY,IOK,pIOK)
  IV = 0
  PV = 0
==
1
--
SV = PVIV(0x****) at 0x****
  REFCNT = 1
  FLAGS = (PADMY,IOK,pIOK)
  IV = 1
  PV = 0
==
""
--
SV = PVIV(0x****) at 0x****
  REFCNT = 1
  FLAGS = (PADMY,POK,pPOK)
  IV = 1
  PV = 0x**** ""\0
  CUR = 0
  LEN = 8
