---
layout: post
title: "Check your pg_dump compression levels"
date: 2015-12-07 20:00:00 -0500
comments: true
tags:
- postgresql
- pg_dump
---
I was idly wondering what was taking `pg_dump` so long and noticed
that it always seemed to be pegged at 100% CPU usage on the client.
That was surprising because naively one might think that the
bottleneck are the server's or the client's disk or the network.
Profiling quickly revealed that the compression library zlib was
taking most of the run time on the client.  And indeed, turning
compression off caused `pg_dump` to fly without getting anywhere near
100% CPU.

When using the custom output format in `pg_dump` (`-Fc`), the output
is automatically compressed, using the same default level that `gzip`
uses.  By using the option `-Z`, one can select a compression level
between 0 (off) and 9 (highest).  Although it is not documented, the
default corresponds to level 6.

Some simple testing has shown that lowering the level from 6 to 1 can
speed up the dump run time by a factor of 3 or more while only
increasing the output size by 10%.  Even the levels in between give
significant speed increases with only minimal differences in output
size.  On the other hand, increasing the compression level to 9 only
decreases the output size by about 1% while causing slow downs by a
factor of 2.  (In this test, level 1 was about twice as slow as no
compression, but the output size was about 40% of the uncompressed
size.  So using at least some compression was still desirable.)

I encourage experimentation with these numbers.  I might actually
default my scripts to `-Z1` in the future.
