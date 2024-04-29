---
title: "PostgreSQL supported platforms over time"
comments: true
tags:
- postgresql
---

The recent [discussion about AIX
support](https://www.postgresql.org/message-id/flat/CY5PR11MB63928CC05906F27FB10D74D0FD322%40CY5PR11MB6392.namprd11.prod.outlook.com)
in PostgreSQL (as of now
[removed](https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=0b16bb8776bb834eb1ef8204ca95dd7667ab948b)
in PostgreSQL 17) led me to look through the project's history, to
learn what platforms we have supported when.

In this context, "platform" really means operating system.  One useful
proxy is looking at the files in `src/template/`, because every
supported platform needs to be listed there.  There are other
dimensions, such as what CPU architectures are supported.
Historically, this was tied to the operating system (e.g., HP-UX/HPPA,
Alpha/Tru64, AIX/PPC, Irix/MIPS), but nowadays, the combinations are
more plentiful.  CPU support in PostgreSQL might be the subject of a
future article.

As usual, at some point in the distant past, this was all very murky
and hard to decipher from the source code history, so let's start with …

* PostgreSQL 6.5 (1999) was the first mention in the source code of
  support for building on Windows, using MinGW (essentially GCC).  I
  wonder what you could do with this then?  It's [listed in the
  release
  notes](https://www.postgresql.org/docs/6.5/release14025.htm)!  But
  official full Windows support didn't come until much later, so this
  must have been quite limited.

* PostgreSQL 7.1 (2001) added QNX, BeOS, and macOS (a.k.a. Darwin).
  With hindsight, one of these is not like the other!

At this point, PostgreSQL supported a formidable 22 platforms.

Also, the [PostgreSQL build farm](https://buildfarm.postgresql.org/)
started in 2004.  Over time, we have developed a quasi-policy that a
platform needs to be represented in the build farm to be considered
officially supported.

* PostgreSQL 8.0 (2005) added native Windows server.  This completed
  the work started around PostgreSQL 6.5.

* PostgreSQL 8.2 (2006) removed QNX and BeOS.  It added support for
  building for Windows using MSVC (Microsoft's Visual C compiler
  suite).

* PostgreSQL 9.2 (2012) began the great purges.  This release removed
  DG/UX, NeXTSTEP, SunOS&nbsp;4 (pre-Solaris), SVR 4, Ultrix, Univel, and
  BSDi.  For some of these, I don't even remember what they were.
  Also, I'm pretty sure a lot of those were already long broken at
  this point.

* PostgreSQL 9.4 (2014) removed Irix.

* PostgreSQL 9.5 (2016) removed Tru64 (known by various names before) and support for Alpha CPUs.

* PostgreSQL 10: (2017) removed SCO OpenServer and UnixWare (shudder).

* PostgreSQL 16 (2023) removed HP-UX.

* PostgreSQL 17 has, as of right now, removed AIX.  We also removed
  the MSVC build system for Windows, but of course we have had the new
  Meson one since PostgreSQL 16 to take its place.

Right now, there are 8 top-level supported platforms left:

* Cygwin
* Darwin (macOS)
* FreeBSD
* Linux
* NetBSD
* OpenBSD
* Solaris
* Windows

Still, there are more platform variants that are not visible at the
top level.  Since many of these platforms are open-source, anyone can
just make a new variant, and if it's just too much different from its
parent, it needs to be tracked separately.  For example,

* MSYS2 is a variant of Cygwin, but it reports itself differently, so
  we had to add support for it explicitly (PostgreSQL 13, 2020).

* PostgreSQL 9.1 (2011) added support for DragonFlyBSD.  This is not a
  top-level platform in PostgreSQL (it's covered by the NetBSD
  template, interestingly enough, even though it's derived from
  FreeBSD), but it's a rare addition of a new operating system
  nonetheless.

* Illumos, which was forked off OpenSolaris at some point, continues
  to be supported.

* PostgreSQL 17 adds support for building the client libraries on
  Android.  Of course, this is Linux underneath, but the userland is
  quite different.  (As far as I know, you can use the Darwin port to
  compile the client libraries for iOS.  But this is not officially
  tracked.)

* There have recently been
  [discussions](https://www.postgresql.org/message-id/flat/fddd1cd6-dc16-40a2-9eb5-d7fef2101488%40technowledgy.de)
  about improving support for [musl](https://musl.libc.org/), an
  alternative C standard library for Linux.

* There are a number of different variants for building and running on
  Windows.  They have many things in common, but they also need to be
  maintained separately.  I had unpacked that in a [previous
  article](https://www.2ndquadrant.com/en/blog/developing-postgresql-windows-part-1/).

It seems unlikely that we'll add many more top-level platforms
anymore, but I expect more work on supporting such platform
sub-variants in the future.
