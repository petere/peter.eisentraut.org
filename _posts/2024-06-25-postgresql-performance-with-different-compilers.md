---
title: "PostgreSQL performance with different compilers"
comments: true
tags:
- clang
- gcc
- postgresql
---

I have tested several times [which compiler builds PostgreSQL the
fastest]({% post_url 2024-05-21-new-compilers-new-timings %}).  Now
let's look at with which compiler PostgreSQL _runs_ the fastest.

Obviously, there are a lot of ways to test this, a lot of ways to
benchmark PostgreSQL.  I picked something really simple here:
[pgbench](https://www.postgresql.org/docs/16/pgbench.html) using the
"select-only" workload and with the default scale and one client.
This should eliminate many concurrency and I/O issues that are
probably mostly unrelated to what the compiler can affect.  (So, it's
just `pgbench -i` followed by `pgbench -S -T 60`.)  Maybe I'll explore
other tests in the future.

I tested the usual range of clang and gcc compilers that I had
available.  I also tested the different [optimization options offered
by
Meson](https://mesonbuild.com/Builtin-options.html#details-for-buildtype):
"debug" (effectively `-O0 -g`), "debugoptimized" (`-O2 -g`, this is
the default for PostgreSQL), "release" (`-O3`), and "minsize" (`-Os
-g`).  The tests are done on tag `REL_16_3`.

The numbers in the following table are transactions per second (tps)
as reported by pgbench (higher is better):

| OS       | Compiler         | debug | debugoptimized | release | minsize |
|----------|------------------|-------|----------------|---------|---------|
| macOS 14 | gcc-14           | 20305 | 48404          | 48942   | 42666   |
|          | gcc-13           | 20325 | 48164          | 48804   | 43537   |
|          | gcc-12           | 20058 | 47761          | 48279   | 44425   |
|          | gcc-11           | 20209 | 47893          | 48150   | 44585   |
|          | clang-18         | 23597 | 48550          | 48816   | 42338   |
|          | clang-17         | 23404 | 48531          | 48337   | 41903   |
|          | clang-16         | 23479 | 48462          | 47638   | 42153   |
|          | clang-15         | 23754 | 48338          | 48401   | 42249   |
|          | clang-14         | 23521 | 47179          | 48310   | 42215   |
|          | clang-13         | 25748 | 48333          | 48115   | 41933   |
|          | Apple clang (15) | 23440 | 48349          | 48557   | 40516   |

Or as a picture:

![PostgreSQL pgbench performance with different compilers](/assets/2024-06/pg-compiler-perf.svg)

Some observations:

* There is very little performance difference between gcc and clang
  (less than 1% with the latest versions).

* Performance across versions in a family does appear to improve a
  little bit over time, but probably not enough to go out of one's way
  to upgrade a compiler (at most about 1% between oldest and newest
  version in each family here).

* The "release" setting offers very little improvement over the
  default "debugoptimized" setting (at most about 1% with the latest
  versions).

* "minsize" is definitely slower than the default (about 10% slower),
  so I wouldn't recommend it for production builds.  (I did spot-check
  that minsize actually made the binaries smaller, but didn't do a
  full analysis.  But in any case, I don't think this is interesting
  for a use case like PostgreSQL.)

In conclusion, as far as this test is concerned, I think using the
default compiler with the default build type is good enough.
