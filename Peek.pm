package Data::Peek;

use strict;
use warnings;

use DynaLoader ();

use vars qw( $VERSION @ISA @EXPORT );
$VERSION = "0.21";
@ISA     = qw( DynaLoader Exporter );
@EXPORT  = qw( DDumper DPeek DDump DDual );
$] >= 5.007003 and push @EXPORT, "DDump_IO";

bootstrap Data::Peek $VERSION;

### ############# DDumper () ##################################################

use Data::Dumper;

sub DDumper
{
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Indent   = 1;

    my $s = Data::Dumper::Dumper @_;
    $s =~ s!^(\s*)'([^']*)'\s*=>!sprintf "%s%-16s =>", $1, $2!gme;	# Align => '
    $s =~ s!^(?= *[]}](?:[;,]|$))!  !gm;
    $s =~ s!^(\s+)!$1$1!gm;

    defined wantarray or print STDERR $s;
    return $s;
    } # DDumper

### ############# DDump () ####################################################

our $has_perlio;

BEGIN {
    use Config;
    $has_perlio = ($Config{useperlio} || "undef") eq "define";
    }

sub _DDump_ref
{
    my ($var, $down) = (@_, 0);

    my $ref = ref $var;
    if ($ref eq "SCALAR" || $ref eq "REF") {
	my %hash = DDump ($$var, $down);
	return { %hash };
	}
    if ($ref eq "ARRAY") {
	my @list;
	foreach my $list (@$var) {
	    my %hash = DDump ($list, $down);
	    push @list, { %hash };
	    }
	return [ @list ];
	}
    if ($ref eq "HASH") {
	my %hash;
	foreach my $key (sort keys %$var) {
	    $hash{DPeek ($key)} = { DDump ($var->{$key}, $down) };
	    }
	return { %hash };
	}
    undef;
    } # _DDump_ref

sub _DDump
{
    my ($var, $down, $dump, $fh) = (@_, "");

    if ($has_perlio and open $fh, ">", \$dump) {
	#print STDERR "Using DDump_IO\n";
	DDump_IO ($fh, $var, $down);
	close $fh;
	}
    else {
	#print STDERR "Using DDump_XS\n";
	$dump = DDump_XS ($var);
	}

    return $dump;
    } # _DDump

sub DDump ($;$)
{
    my ($var, $down) = (@_, 0);
    my @dump = split m/[\r\n]+/, _DDump ($var, wantarray || $down) or return;

    if (wantarray) {
	my %hash;
	($hash{sv} = $dump[0]) =~ s/^SV\s*=\s*//;
	m/^\s+(\w+)\s*=\s*(.*)/ and $hash{$1} = $2 for @dump;

	if (exists $hash{FLAGS}) {
	    $hash{FLAGS} =~ tr/()//d;
	    $hash{FLAGS} = { map { $_ => 1 } split m/,/ => $hash{FLAGS} };
	    }

	$down && ref $var and
	    $hash{RV} = _DDump_ref ($var, $down - 1) || $var;
	return %hash;
	}

    my $dump = join "\n", @dump, "";

    defined wantarray and return $dump;

    print STDERR $dump;
    } # DDump

"Indent";

__END__

=head1 NAME

Data::Peek - A collection of low-level debug facilities

=head1 SYNOPSIS

 use Data::Peek;

 print DDumper \%hash;    # Same syntax as Data::Dumper

 print DPeek \$var;
 my ($pv, $iv, $nv, $rv, $magic) = DDual ($var [, 1]);
 print DPeek for DDual ($!, 1);

 my $dump = DDump $var;
 my %hash = DDump \@list;
 DDump \%hash;

 my %hash = DDump (\%hash, 5);  # dig 5 levels deep

 my $dump;
 open my $fh, ">", \$dump;
 DDump_IO ($fh, \%hash, 6);
 close $fh;
 print $dump;

=head1 DESCRIPTION

Data::Peek started off as C<DDumper> being a wrapper module over
L<Data::Dumper>, but grew out to be a set of low-level data
introspection utilities that no other module provided yet, using the
lowest level of the perl internals API as possible.

=head2 DDumper ($var, ...)

Not liking the default output of Data::Dumper, and always feeling the need
to set C<$Data::Dumper::Sortkeys = 1;>, and not liking any of the default
layouts, this function is just a wrapper around Data::Dumper::Dumper with
everything set as I like it.

    $Data::Dumper::Sortkeys = 1;
    $Data::Dumper::Indent   = 1;

And the result is further beautified to meet my needs:

  * quotation of hash keys has been removed (with the disadvantage
    that the output might not be parseable again).
  * arrows for hashes are aligned at 16 (longer keys don't align)
  * closing braces and brackets are now correctly aligned

In void context, C<DDumper ()> prints to STDERR.

Example

  print DDumper { ape => 1, foo => "egg", bar => [ 2, "baz", undef ]};

  $VAR1 = {
      ape              => 1,
      bar              => [
          2,
          'baz',
          undef
          ],
      foo              => 'egg'
      };

=head2 DPeek

=head2 DPeek ($var)

Playing with C<sv_dump ()>, I found C<Perl_sv_peek ()>, and it might be
very useful for simple checks. If C<$var> is omitted, uses $_.

Example

  print DPeek "abc\x{0a}de\x{20ac}fg";

  PV("abc\nde\342\202\254fg"\0) [UTF8 "abc\nde\x{20ac}fg"]

=head2 DDual ($var [, $getmagic])

DDual will return the basic elements in a variable, guaranteeing that no
conversion takes place. This is very useful for dual-var variables, or
when checking is a variable has defined entries for a certain type of
scalar. For each Integer (IV), Double (NV), String (PV), and Reference (RV),
the current value of C<$var> is returned or undef if it is not set (yet).
The 5th element is an indicator if C<$var> has magic, which is B<not> invoked
in the returned values, unless explicitly asked for with a true optional
second argument.

Example

  print DPeek for DDual ($!, 1);

=head3 DDump ($var [, $dig_level])

A very useful module when debugging is C<Devel::Peek>, but is has one big
disadvantage: it only prints to STDERR, which is not very handy when your
code wants to inspect variables al a low level.

Perl itself has C<sv_dump ()>, which does something similar, but still
prints to STDERR, and only one level deep.

C<DDump ()> is an attempt to make the innards available to the script level
with a reasonable level of compatibility. C<DDump ()> is context sensitive.

In void context, it behaves exactly like C<Perl_sv_dump ()>.

In scalar context, it returns what C<Perl_sv_dump ()> would have printed.

In list context, it returns a hash of the variable's properties. In this mode
you can pass an optional second argument that determines the depth of digging.

Example

  print scalar DDump "abc\x{0a}de\x{20ac}fg"

  SV = PV(0x723250) at 0x8432b0
    REFCNT = 1
    FLAGS = (PADBUSY,PADMY,POK,pPOK,UTF8)
    PV = 0x731ac0 "abc\nde\342\202\254fg"\0 [UTF8 "abc\nde\x{20ac}fg"]
    CUR = 11
    LEN = 16

  my %h = DDump "abc\x{0a}de\x{20ac}fg";
  print DDumper \%h;

  $VAR1 = {
      CUR              => '11',
      FLAGS            => {
          PADBUSY          => 1,
          PADMY            => 1,
          POK              => 1,
          UTF8             => 1,
          pPOK             => 1
          },
      LEN              => '16',
      PV               => '0x731ac0 "abc\\nde\\342\\202\\254fg"\\0 [UTF8 "abc\\nde\\x{20ac}fg"]',
      REFCNT           => '1',
      sv               => 'PV(0x723250) at 0x8432c0'
      };

  my %h = DDump {
      ape => 1,
      foo => "egg",
      bar => [ 2, "baz", undef ],
      }, 1;
  print DDumper \%h;

  $VAR1 = {
      FLAGS            => {
          PADBUSY          => 1,
          PADMY            => 1,
          ROK              => 1
          },
      REFCNT           => '1',
      RV               => {
          PVIV("ape")      => {
              FLAGS            => {
                  IOK              => 1,
                  PADBUSY          => 1,
                  PADMY            => 1,
                  pIOK             => 1
                  },
              IV               => '1',
              REFCNT           => '1',
              sv               => 'IV(0x747020) at 0x843a10'
              },
          PVIV("bar")      => {
              CUR              => '0',
              FLAGS            => {
                  PADBUSY          => 1,
                  PADMY            => 1,
                  ROK              => 1
                  },
              IV               => '1',
              LEN              => '0',
              PV               => '0x720210 ""',
              REFCNT           => '1',
              RV               => '0x720210',
              sv               => 'PVIV(0x7223e0) at 0x843a10'
              },
          PVIV("foo")      => {
              CUR              => '3',
              FLAGS            => {
                  PADBUSY          => 1,
                  PADMY            => 1,
                  POK              => 1,
                  pPOK             => 1
                  },
              IV               => '1',
              LEN              => '8',
              PV               => '0x7496c0 "egg"\\0',
              REFCNT           => '1',
              sv               => 'PVIV(0x7223e0) at 0x843a10'
              }
          },
      sv               => 'RV(0x79d058) at 0x843310'
      };

=head2 DDump_IO ($io, $var [, $dig_level])

A wrapper function around perl's internal C<Perl_do_sv_dump ()>, which
makes C<Devel::Peek> completely superfluous. As PerlIO is only available
perl version 5.7.3 and up, this function is not available in older perls.

Example

  my $dump;
  open my $eh, ">", \$dump;
  DDump_IO ($eh, { 3 => 4, ape => [5..8]}, 6);
  close $eh;
  print $dump;

  SV = RV(0x79d9e0) at 0x843f00
    REFCNT = 1
    FLAGS = (TEMP,ROK)
    RV = 0x741090
      SV = PVHV(0x79c948) at 0x741090
        REFCNT = 1
        FLAGS = (SHAREKEYS)
        IV = 2
        NV = 0
        ARRAY = 0x748ff0  (0:7, 2:1)
        hash quality = 62.5%
        KEYS = 2
        FILL = 1
        MAX = 7
        RITER = -1
        EITER = 0x0
          Elt "ape" HASH = 0x97623e03
          SV = RV(0x79d9d8) at 0x8440e0
            REFCNT = 1
            FLAGS = (ROK)
            RV = 0x741470
              SV = PVAV(0x7264b0) at 0x741470
                REFCNT = 2
                FLAGS = ()
                IV = 0
                NV = 0
                ARRAY = 0x822f70
                FILL = 3
                MAX = 3
                ARYLEN = 0x0
                FLAGS = (REAL)
                  Elt No. 0
                  SV = IV(0x7467c8) at 0x7c1aa0
                    REFCNT = 1
                    FLAGS = (IOK,pIOK)
                    IV = 5
                  Elt No. 1
                  SV = IV(0x7467b0) at 0x8440f0
                    REFCNT = 1
                    FLAGS = (IOK,pIOK)
                    IV = 6
                  Elt No. 2
                  SV = IV(0x746810) at 0x75be00
                    REFCNT = 1
                    FLAGS = (IOK,pIOK)
                    IV = 7
                  Elt No. 3
                  SV = IV(0x746d38) at 0x7799d0
                    REFCNT = 1
                    FLAGS = (IOK,pIOK)
                    IV = 8
          Elt "3" HASH = 0xa400c7f3
          SV = IV(0x746fd0) at 0x7200e0
            REFCNT = 1
            FLAGS = (IOK,pIOK)
            IV = 4

=head1 INTERNALS

C<DDump ()> uses an XS wrapper around C<Perl_sv_dump ()> where the
STDERR is temporarily caught to a pipe. The internal XS helper functions
are not meant for user space

=head2 DDump_XS (SV *sv)

Base interface to internals for C<DDump ()>.

=head1 BUGS

Not all types of references are supported.

It might crash.

No idea how far back this goes in perl support.

=head1 SEE ALSO

L<Devel::Peek(3)>, L<Data::Dumper(3)>, L<Data::Dump(3)>,
L<Data::Dump::Streamer(3)>

=head1 AUTHOR

H.Merijn Brand <h.m.brand@xs4all.nl>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2008 H.Merijn Brand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
