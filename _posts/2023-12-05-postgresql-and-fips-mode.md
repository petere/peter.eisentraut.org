---
title: "PostgreSQL and FIPS mode"
comments: true
tags:
- openssl
- postgresql
---

PostgreSQL users sometimes ask whether PostgreSQL supports FIPS mode,
whatever that might actually mean.  "FIPS mode" is a thing provided by
OpenSSL that, well, makes it more secure and prevents the use of old
encryption methods, is I suppose a rough way to describe it?  It has
some interesting effects on PostgreSQL, which uses OpenSSL for various
cryptographic purposes.

## What is FIPS mode?

First, we should unpack what "FIPS mode" is.

FIPS stands for "Federal Information Processing Standard".  It is a
series of standards published by the National Institute of Standards
and Technology (NIST) for use by the United States federal government.
So without further context, "FIPS" by itself isn't any more meaningful
than, say, "ISO" or "RFC".  The standard that we usually mean when
talking about FIPS in the context of encryption and SSL libraries is
FIPS 140, "Security Requirements for Cryptographic Modules".  (But
there are are also other FIPS standards related to encryption and
security, such as FIPS 197 (AES) and FIPS 198 (HMAC).)

The FIPS standards are by their original purpose only applicable when
dealing with the United States federal government or its contractors.
But many organizations apply these standards anyway, by their internal
policies or indirect requirements, and so they come up quite a lot.

There are multiple versions of FIPS 140: FIPS 140-1, FIPS 140-2, FIPS
140-3.  Each version supersedes the previous one.  (So the naming here
is a bit different from ISO standards, where for example ISO 8601-1
and ISO 8601-2 are two concurrently existing parts, not subsequent
versions.)  FIPS 140-1 was published in 1994 and is no longer relevant
now.  FIPS 140-2 was published in 2001 and is the one most people
refer to.  FIPS 140-3 was published in 2019, but somehow the adoption
didn't quite happen at the pace anticipated, so -2 is still being
used, and it's the one that most people actually mean.  (Of course,
when dealing with an entity that requires FIPS 140 conformance, you
need to ascertain which version they require.)

There are now also ISO standards in this area: [ISO/IEC
19790](https://www.iso.org/standard/52906.html), "Security
requirements for cryptographic modules", and [ISO/IEC
24759](https://www.iso.org/standard/72515.html), "Test requirements
for cryptographic modules".  These were derived directly from FIPS
140-2.  This supports the fact that these standards are no longer used
just in the context of the United States government.  In fact, one of
the changes in FIPS 140-3 over previous versions is that it just
refers to those ISO/IEC standards and makes some local modifications:
[FIPS
140-2](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.140-2.pdf) is
69 pages; [FIPS
140-3](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.140-3.pdf) is
just 11 pages, which essentially say, "read these other standards".
(I can't help but feel that this contributes to the slow adoption and
low relevance of FIPS 140-3: You can read FIPS 140-2 online in its
entirety.  To read FIPS 140-3, you need to purchase additional
documents.)

FIPS 140-2 defines four security levels (level 1 though level 4) that
"cryptographic modules" can aim to achieve.  Level 1 mainly specifies
that only approved algorithms and modes of operation may be used.  The
levels beyond that mainly deal with physical access, tamper detection,
etc., so not something that a software-only product can do.

## FIPS and OpenSSL

By default, out of the box, OpenSSL does not satisfy the requirements
of FIPS 140-2.  But some versions (see below) can be configured to
operate in a mode that satisfies FIPS 140-2.

In the history of OpenSSL, there have been two mostly separate
implementations of FIPS support.  The first was in release 1.0.2.
This support was later removed in version 1.1.0.  You will mainly see
this nowadays in Red Hat operating systems, such as in RHEL until
version 8, and in Fedora until version 35.  (The FIPS support has been
forward ported, so it's also included in some packages with versions
1.1.x.)

Red Hat built [further
integration](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/security_hardening/assembly_installing-a-rhel-8-system-with-fips-mode-enabled_security-hardening)
around this into their operating systems.  The approach is that you
switch your whole operating system into "FIPS mode" at boot time, and
then the OpenSSL library is also aware of this and uses its FIPS mode
internally.

The second implementation was added in version 3.0.  This has a
completely different internal architecture.  Whereas the 1.0.2-era
implementation essentially contains a bunch of if-statements to reject
unapproved algorithms, like `if (FIPS_mode()) { some_error(); }`, the
new implementation puts all cryptographic routines into loadable
"provider" modules, and depending on the configuration you load the
"default" provider module, which contains a wider but unapproved
selection of cryptographic routines, or the ["fips"
provider](https://www.openssl.org/docs/man3.0/man7/OSSL_PROVIDER-FIPS.html)
module, which contains a narrower but approved set of routines (and
there are also more providers for other purposes, such as the "legacy"
provider).

Many users, including government users, won't just want to take the
vendor's word about FIPS 140 conformance.  NIST also officially
validates components for conformance to FIPS 140.  OpenSSL 3.0 has
been
[validated](https://www.openssl.org/blog/blog/2022/08/24/FIPS-validation-certificate-issued/)
by NIST and a
[certificate](https://csrc.nist.gov/projects/cryptographic-module-validation-program/certificate/4282)
has been issued.  (Note that this validation currently does not cover
versions newer than 3.0, such as 3.1 and 3.2.)

That is my reconstruction and summary of the situation.  I'm sure
there are more details if you look further.  In practice, as of this
writing, you can get a FIPS-enabled OpenSSL installation either from a
Red Hat operating system or by building OpenSSL 3.x from source.  (Or
you dig up the sources of OpenSSL 1.0.2 and try to set it up.)

So "FIPS mode" in OpenSSL either means you have a 1.x-era OpenSSL and
you literally turn on the "FIPS mode", or you have a 3.x-era OpenSSL
and you configure it to load the "fips" provider instead of the
"default" provider.

## FIPS and PostgreSQL

Now how does this impact PostgreSQL?

PostgreSQL is, of course, itself not really a "cryptographic module",
and so it is not in the scope of FIPS 140.

PostgreSQL uses cryptographic routines in a few different places:

* For transport security, for SSL/TLS for network communication.
  (Indirectly, this also includes things like the connections to LDAP
  servers, which use some LDAP library, which in turn might use
  OpenSSL.)

* For internal use by cryptographic operations, such as hashing
  functions used during authentication protocols (SCRAM-SHA-256, MD5).

* The [pgcrypto](https://www.postgresql.org/docs/16/pgcrypto.html)
  extension exposes a number of cryptographic routines (encryption,
  digests, signatures) as SQL-callable functions.  This are
  essentially passed straight through to the underlying OpenSSL
  implementations.

When you turn on FIPS mode in OpenSSL, each of these calls will then
internally be routed to the FIPS-140-compatible routines.

For SSL/TLS, this shouldn't make a difference in practice.  The TLS
protocol negotiates a cipher suite between the client and the server,
and unless both of these use particularly bad configurations, they
should end up using modern and FIPS-approved algorithms.  (Not TLS
configuration advice!)  Also, in TLS 1.3, all uses of MD5 have been
removed from the specification.  So as long as you stay within the
range of non-deprecated TLS versions and use sensible configurations,
it wouldn't make a difference externally.  Internally, it would be
using the FIPS-certified code instead of the non-certified code.  That
shouldn't make a practical difference, but maybe it can make you feel
good.

The second point is more interesting.  Up until PostgreSQL major
version 13, the hashing functions required for authentication
(specifically MD5 and SHA-256) were provided internally by PostgreSQL.
[Starting in PostgreSQL
14](https://www.postgresql.org/docs/14/release-14.html#id-1.11.6.15.5.14),
these functions are routed to OpenSSL if PostgreSQL is built with
OpenSSL (which is most typical).  (The internal implementations still
exist but are only used if no OpenSSL support is built.)  This is
especially meaningful because MD5 is not among the algorithms approved
by FIPS 140-2.  So when you have PostgreSQL 14 or newer running with
an OpenSSL in FIPS mode, then all MD5 calls will fail, and as a
result, any MD5 authentication will fail, and you can't even create an
MD5-hashed password anymore.  Now, the MD5 authentication is pretty
much deprecated (SCRAM should be used instead), but a lot of people
got tripped up by that when it first came out.

pgcrypto is more of a mixed bag.  It supports a variety of encryption
algorithms, for example AES, Blowfish, CAST5.  Some of these are not
among the ones approved by FIPS 140-2.  When you switch OpenSSL to
FIPS mode, the calls to unsupported algorithms will fail, but the
supported ones will still work.  Until PostgreSQL 14, pgcrypto also
had built-in fallback implementations of some encryption algorithms,
for use when OpenSSL support was not enabled, but this has been
[removed in PostgreSQL
15](https://www.postgresql.org/docs/15/release-15.html#id-1.11.6.10.5.13).
(Note: The [`crypt()` and
`gen_salt()`](https://www.postgresql.org/docs/16/pgcrypto.html#PGCRYPTO-PASSWORD-HASHING-FUNCS)
functions in pgcrypto do not use OpenSSL and are therefore not
affected by FIPS mode, even though they offer some algorithms not
approved by FIPS 140.)

The latest thing I have been working on, which is why I had to look
all of this up again, is to make the internal test suites of
PostgreSQL pass in FIPS mode.  Why does that matter?

One reason is that this will be helpful if your development
environment is running in FIPS mode.  That's probably not common for
developers (and until this change they would have had a very hard
time).  But the test suites are also run at other times, for example
during packaging.  So it can be good that that works.

Second, it's good to know that the system still behaves when the FIPS
mode disables some things.  For example, as mentioned, the FIPS mode
prevents the creation of passwords for MD5 authentication.  But does
the system handle that error properly?  Yes it does.  But some time
ago, before we started paying attention to this, some code assumed
that the MD5 hashing function can never fail.

Third, it's plausible that we will want to add more encryption and
other cryptographic functionality into PostgreSQL over time.  The
SCRAM-SHA-256 authentication method was such a thing; maybe we want to
add more like that.  Some kind of encryption might be another.  It's
good to be able to verify that all of this will still work in FIPS
mode.  This will alert us if implementations use unapproved methods or
some methods have gotten deprecated over time.

Fixing the test suites was fairly involved and required changes in
several areas.  The most frequent problem was that a lot of tests used
the `md5()` function to generate some test data.  This usually looked
something like `SELECT x, md5(x::text) FROM generate_series(-10,10)
x`.  This can be replaced with something involving a different hash
function — in our case we used `sha256()` — and adjusting the test
output accordingly.  These changes were done in PostgreSQL 16 for the
core regression tests (what you run with `make check`).  The remaining
changes for the other test suites are in PostgreSQL 17-to-be.  Then,
we needed to fix some test fixtures in the SSL test suite that relied
(in some mysterious and poorly documented ways) on non-FIPS
algorithms.  Also, various tests that relied on MD5 authentication
needed to be adjusted or selectively disabled.  Finally, for pgcrypto
and a few remaining in-core regression tests, alternative expected
files were added, so that either the normal behavior or the error
behavior in FIPS mode is accepted.  All these changes are now in
PostgreSQL 17-to-be.

It's important to keep in mind, however, that this doesn't actually
prove anything about the security of PostgreSQL or its implementation.
It just says that if PostgreSQL is used with OpenSSL in FIPS mode, it
still works reasonably.  (For example, the deprecated MD5
authentication method could in theory be re-implemented using a newer
and FIPS-approved hashing function such as SHA-256, but the underlying
authentication protocol would still be crappy.  Also, in general,
higher-level protocols such as authentication exchanges and TLS are
outside the scope of FIPS 140 anyway.)

## Summary

* PostgreSQL ≥14: hashing functions routed to OpenSSL; MD5 authentication will fail in FIPS mode
* PostgreSQL ≥15: pgcrypto requires OpenSSL, subject to FIPS mode
* PostgreSQL ≥17: all PostgreSQL test suites pass with OpenSSL in FIPS mode

So now, if someone asks whether PostgreSQL supports FIPS mode, we have
some answers to point to.
