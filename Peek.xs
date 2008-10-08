/*  Copyright (c) 2008-2008 H.Merijn Brand.  All rights reserved.
 *  This program is free software; you can redistribute it and/or
 *  modify it under the same terms as Perl itself.
 */

#ifdef __cplusplus
extern "C" {
#endif
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include "ppport.h"
#ifdef __cplusplus
}
#endif

SV *_DDump (SV *sv)
{
    int   err[3], n;
    char  buf[128];
    SV   *dd;
    dTHX;

    if (pipe (err)) return (NULL);

    dd = sv_newmortal ();
    err[2] = dup (2);
    close (2);
    if (dup (err[1]) == 2)
	Perl_sv_dump (aTHX_ sv);
    close (err[1]);
    close (2);
    err[1] = dup (err[2]);
    close (err[2]);

    Perl_sv_setpvn (aTHX_ dd, "", 0);
    while ((n = read (err[0], buf, 128)) > 0)
#if PERL_VERSION >= 8
	/* perl 5.8.0 did not export Perl_sv_catpvn */
	Perl_sv_catpvn_flags (aTHX_ dd, buf, n, SV_GMAGIC);
#else
	Perl_sv_catpvn       (aTHX_ dd, buf, n);
#endif
    return (dd);
    } /* _DDump */

MODULE = Data::Peek		PACKAGE = Data::Peek

void
DPeek (...)
  PROTOTYPE: ;$
  PPCODE:
    ST (0) = newSVpv (Perl_sv_peek (aTHX_ items ? ST (0) : DEFSV), 0);
    XSRETURN (1);
    /* XS DPeek */

void
DDual (sv, ...)
    SV   *sv

  PROTOTYPE: $;$
  PPCODE:
    if (items > 1 && SvGMAGICAL (sv) && SvTRUE (ST (1)))
	mg_get (sv);

    if (SvPOK (sv) || SvPOKp (sv)) {
	SV *xv = newSVpv (SvPVX (sv), 0);
	if (SvUTF8 (sv)) SvUTF8_on (xv);
	mPUSHs (xv);
	}
    else
	PUSHs (&PL_sv_undef);

    if (SvIOK (sv) || SvIOKp (sv))
	mPUSHi (SvIV (sv));
    else
	PUSHs (&PL_sv_undef);

    if (SvNOK (sv) || SvNOKp (sv))
	mPUSHn (SvNV (sv));
    else
	PUSHs (&PL_sv_undef);

    if (SvROK (sv)) {
	SV *xv = newSVsv (SvRV (sv));
	mPUSHs (xv);
	}
    else
	PUSHs (&PL_sv_undef);

    mPUSHi (SvMAGICAL (sv) >> 21);
    /* XS DDual */

void
DDump_XS (sv)
    SV   *sv

  PROTOTYPE: $
  PPCODE:
    SV   *dd = _DDump (sv);

    if (dd) {
	ST (0) = dd;
	XSRETURN (1);
	}

    XSRETURN (0);
    /* XS DDump */

#if PERL_VERSION >= 8

void
DDump_IO (io, sv, level)
    PerlIO *io
    SV     *sv
    IV      level

  PPCODE:
    Perl_do_sv_dump (aTHX_ 0, io, sv, 1, level, 1, 0);
    XSRETURN (1);
    /* XS DDump */

#endif
