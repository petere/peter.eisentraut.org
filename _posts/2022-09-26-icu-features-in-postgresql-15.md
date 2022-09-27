---
layout: post
title: "ICU features in PostgreSQL 15"
comments: true
tags:
- icu
- postgresql
---

One of the [new features in PostgreSQL
15](https://www.postgresql.org/docs/15/release-15.html) is that you
can use ICU collations on a database and instance level.

In [PostgreSQL
10](https://www.postgresql.org/docs/10/release-10.html), we first
added ICU support to PostgreSQL.  That allowed you to define collation
objects that use ICU as the backing locale library (called _collation
provider_ or _locale provider_ in PostgreSQL), as an alternative to
the existing "libc" provider.  For example,

	CREATE COLLATION german (provider = icu, locale = 'de');

This opened up the use of various collation customization facilities
provided by ICU, for example

	CREATE COLLATION upperfirst (provider = icu, locale = 'en@colCaseFirst=upper');

(More details in the
[documentation](https://www.postgresql.org/docs/current/collation.html).)

With the introduction of ICU support, we also added [version tracking
of
collations](https://www.postgresql.org/docs/current/sql-altercollation.html),
so that PostgreSQL could detect when the collation definition in the
operating system has changed compared to what it was when PostgreSQL
started using it.  (This support has since been expanded to the libc
collation provider on some platforms.)

Regrettably, all this only allowed you to use ICU selectively for
specific columns that are declared to use ICU-backed collations.  It
wasn't possible to use ICU for the whole database automatically by
default.

This is now possible in PostgreSQL 15.

For example, to initialize a new instance using an ICU locale:

	initdb -D pgdata --locale-provider=icu --icu-locale=de

Of course, you can also use advanced ICU features, like

	initdb -D pgdata --locale-provider=icu --icu-locale='en@colCaseFirst=upper'

There are some lingering problems: It's not easy to completely excise
the libc locales from the operation of the server.

First, there is still some code in PostgreSQL proper that uses libc
locale facilities.  The only code that I'm aware of that has
noticeable impact in practice is the text search code's "isalpha"
etc. tests.  Eventually, we should convert all that to use ICU library
calls instead, if so configured.

Second, analogous issues could exist in extensions, and that's a lot
harder to track down.

Third, libc locale settings interact with each other in not completely
obvious ways.  For example, if you use gettext to localize program
messages, this is configured using the `LC_MESSAGES` locale setting,
which can be changed at any time.  But the `LC_CTYPE` setting that is
attached to the database determines the encoding that gettext uses.
So you need to set that to something that matches the database
encoding, or else the gettext output will be encoded incorrectly.

Therefore, at the moment, you still need to set a libc locale in any
case.  So invocations might look like

	initdb -D pgdata --locale-provider=icu --icu-locale=de --locale=de_DE.utf8

I realize this is quite confusing, but at least the complexity is
contained to the
[`initdb`](https://www.postgresql.org/docs/15/app-initdb.html) call
(and optionally the
[`createdb`](https://www.postgresql.org/docs/15/app-createdb.html)
call).  (Of course, the `--locale` option defaults to the locale
environment settings, as before.)

(Practical note: For both the text search and the gettext issue, the
actual `lc_ctype` locale doesn't make a difference, as long as it is
not "C" and matches the database encoding.  So for example, it might
be okay to just hardcode `lc_ctype` to something like `en_US.utf8` in
a deployment script.  This does not affect what language text search
thinks the text is or what the output language of gettext is (so you
can still customize those as you want), it just makes sure that they
handle the character encoding and classification correctly.)

Here is what I plan to work on in the future:

- Fix remaining uses of libc locales that don't observe the ICU
  setting.  We'll have to see how deep this runs.  For example, the
  text search issue is probably a small matter of programming, but the
  gettext issue seems more difficult to fix.

- Nondeterministic collations are not yet supported on the database
  and instance level.  [Nondeterministic
  collations](https://www.postgresql.org/docs/current/collation.html#COLLATION-NONDETERMINISTIC)
  are a feature (new in PostgreSQL 12) that allows you to define, for
  example, case-insensitive or accent-ignoring collations.  But not
  all functions and operators support such collations, so using it for
  the default collation would break some queries, including some used
  in system views, so we have disabled this for now.

  (The nondeterministic collations feature is technically orthogonal
  to the ICU feature.  But since the libc locale provider doesn't
  support nondeterministic collations, it is often thought of as part
  of the ICU feature.)

- We could expose more ICU collation
  [customization](https://unicode-org.github.io/icu/userguide/collation/customization/)
  options through PostgreSQL.  This would give users full flexibility
  if they want to put "B" before "A", or perhaps something less silly.

- I would like to move toward making ICU the default.  I don't know
  whether we'd switch the actual defaults of the `initdb` options.
  But I would like to get to a point where we think ICU and UTF-8
  first, where all binaries are built with ICU enabled, where packages
  or, say, docker images are initialized with ICU collations by
  default.  To get there, we need feedback if there is anything in the
  current setup that isn't fully ready for that.
