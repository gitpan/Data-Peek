#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 42;

BEGIN {
    use_ok "Data::Peek";
    die "Cannot load Data::Peek\n" if $@;	# BAIL_OUT not avail in old Test::More
    }

my ($dump, $var) = ("", "");
while (<DATA>) {
    chomp;
    my ($v, $exp, $re) = split m/\t+ */;

    if ($v eq "--") {
	ok (1, "** $exp");
	next;
	}

    unless ($v eq "") {
	eval "\$var = $v";
	ok ($dump = DDumper ($var),	"DDumper ($v)");
	$dump =~ s/\A\$VAR1 = //;
	$dump =~ s/;\n\Z//;
	}
    if ($re) {
	like ($dump, qr{$exp}m,		".. content $re");
	$1 and print STDERR "# '$1' (", length ($1), ")\n";
	}
    else {
	is   ($dump,    $exp,		".. content");
	}
    }

1;

__END__
--	Basic values
undef				undef
1				1
""				''
"\xa8"				'¨'
1.24				'1.24'
\undef				\undef
\1				\1
\""				\''
\"\xa8"				\'¨'
(0, 1)				1
\(0, 1)				\1
--	Structures
[0, 1]				^\[\n					line 1
				^    0,\n				line 2
				^    1\n				line 3
				^    ]\Z				line 4
[0,1,2]				\A\[\n\s+0,\n\s+1,\n\s+2\n\s+]\Z	line splitting
--	Indentation
[0]				\A\[\n    0\n    ]\Z			single indent
[[0],{foo=>1}]			^\[\n					outer list
				^ {4}\[\n {8}0\n {8}],\n {4}		inner list
				^ {4}\{\n {8}foo {14}=> 1\n {8}}\n	inner hash
				^ {4}]\Z				outer list end
[[0],{foo=>1}]			\A\[\n {4}\[\n {8}0\n {8}],\n {4}\{\n {8}foo {14}=> 1\n {8}}\n {4}]\Z	full struct
