---
title: "Precompiled headers in PostgreSQL"
comments: true
tags:
- postgresql
---

As some readers might be aware, in PostgreSQL, we have been working on
adding a new build system using Meson.  The new Meson build system has
support for precompiled headers.  I wanted to find out how useful that
is.

Here is an explanation of precompiled headers from GCC:
<https://gcc.gnu.org/onlinedocs/gcc/Precompiled-Headers.html>.  Here
is the description of how they work in Meson:
<https://mesonbuild.com/Precompiled-headers.html> (Note, however, that
as someone compiling PostgreSQL with Meson now, this is all taken care
of and you don't need to do anything to be able to use this, other
than turning it on.[^pch])

Lore has it that this is mainly useful for Windows.  So let's check
that.  The following are the run times[^time] of the "build" step
(i.e., just the compiling, no setup, no tests) of the task "Windows -
Server 2019, VS 2019 - Meson & ninja" in the Cirrus CI configuration
("pch" = precompiled headers):

|                   | pch off  | pch on   |
|-------------------|----------|----------|
| VM (current[^vm]) | 2:04 min | 1:13 min |
| container (old)   | 4:19 min | 2:45 min |

The exact times will obviously vary, but this shows the relative
effects pretty well.

So it's useful on Windows.

Is it useful elsewhere?

I gave it a try on the macOS I had handy.  These are the run times of
`meson compile`:

|            | pch off  | pch on   |
|------------|----------|----------|
| ccache off | 1:34 min | 1:26 min |
| ccache on[^cc] | 9.8 s    | 10.7 s   |

I also tried it on a Linux (Debian) host; the results were
essentially identical to these.

So without ccache it is around 10% faster, but with ccache it is
around 10% slower.

To summarize, precompiled headers are definitely useful on Windows,
but on other platforms the impact might not be important enough to
bother with it, and there might even be a slightly negative impact.

[^time]: All timings in this article are the middle of three runs.

[^vm]: The "current" values are from commit
    [`98811323c8`](https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=98811323c8)
    ("ci: Use windows VMs instead of windows containers"), the "old"
    ones from just before that.  As you can see, that change is also
    very effective.

[^pch]: `meson setup ... -Db_pch=true` and `false` respectively.  Note
    that unlike the Meson defaults, pch is off by default in
    PostgreSQL.

[^cc]: When using ccache with pch, you [need to
    set](https://ccache.dev/manual/4.7.4.html#_precompiled_headers)
    `CCACHE_SLOPPINESS=pch_defines,time_macros`.  To be fair/sure, I
    set this also for the pch off test.  I also did one caching run
    before taking timings.  Note that if you don't set this, then
    ccache will be ineffective if pch is enabled.
