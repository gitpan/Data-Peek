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
#define	NEED_pv_pretty
#define	NEED_pv_escape
#define	NEED_my_snprintf
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

#ifdef NO_SV_PEEK

void
DPeek (...)
  PROTOTYPE: ;$
  PPCODE:
    ST (0) = newSVpv ("Your perl did not export Perl_sv_peek ()", 0);
    XSRETURN (1);
    /* XS DPeek */

#else

void
DPeek (...)
  PROTOTYPE: ;$
  PPCODE:
    ST (0) = newSVpv (Perl_sv_peek (aTHX_ items ? ST (0) : DEFSV), 0);
    XSRETURN (1);
    /* XS DPeek */

#endif

void
DDisplay (...)
  PROTOTYPE: ;$
  PPCODE:
    SV *sv  = items ? ST (0) : DEFSV;
    SV *dsp = newSVpv ("", 0);
    if (SvPOK (sv) || SvPOKp (sv))
	Perl_pv_pretty (aTHX_ dsp, SvPVX (sv), SvCUR (sv), 0,
	    NULL, NULL,
	    (PERL_PV_PRETTY_DUMP | PERL_PV_ESCAPE_UNI_DETECT));
    ST (0) = dsp;
    XSRETURN (1);
    /* XS DDisplay */

void
triplevar (pv, iv, nv)
    SV  *pv
    SV  *iv
    SV  *nv

  PROTOTYPE: $$$
  PPCODE:
    SV  *tv = newSVpvs ("");
    SvUPGRADE (tv, SVt_PVNV);

    if (SvPOK (pv) || SvPOKp (pv)) {
	sv_setpvn (tv, SvPVX (pv), SvCUR (pv));
	if (SvUTF8 (pv)) SvUTF8_on (tv);
	}
    else
	sv_setpvn (tv, NULL, 0);

    if (SvNOK (nv) || SvNOKp (nv)) {
	SvNV_set (tv, SvNV (nv));
	SvNOK_on (tv);
	}

    if (SvIOK (iv) || SvIOKp (iv)) {
	SvIV_set (tv, SvIV (iv));
	SvIOK_on (tv);
	}

    ST (0) = tv;
    XSRETURN (1);
    /* XS triplevar */

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
