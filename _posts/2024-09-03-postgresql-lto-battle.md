---
title: "PostgreSQL LTO battle"
comments: true
tags:
- clang
- gcc
- postgresql
---

I [wrote recently]({% post_url
2024-06-25-postgresql-performance-with-different-compilers %}) about
the performance of PostgreSQL when compiled with different compilers
and optimization levels.  Another dimension in that evaluation is
link-time optimization (LTO).

[LTO](https://gcc.gnu.org/onlinedocs/gccint/LTO-Overview.html) allows
the compiler to perform optimizations across source-file boundaries
(more correctly, compilation unit boundaries).

Sounds useful, so let's give it a try.  I'm using the same setup as in
the previous article, except this time I'm up to tag `REL_16_4`.  To
enable LTO, I'm using the [meson option
`-Db_lto`](https://mesonbuild.com/Builtin-options.html#base-options).

As before, the numbers in the following table are transactions per
second (tps) as reported by pgbench (higher is better):

| OS       | Compiler | LTO   | debugoptimized | release |
|----------|----------|-------|----------------|---------|
| macOS 14 | gcc-14   | false | 48063          | 48248   |
|          |          | true  | 49554          | 50427   |
|          | clang-18 | false | 48143          | 47864   |
|          |          | true  | 50014          | 49935   |

These results show that there is a positive effect from LTO, but it is
quite limited.  The improvement is about 3–5% tps, which is not
nothing, but it's also not overwhelming.

I also tried with the "release" buildtype in the hope that it would
result in additional impact, maybe because the compiler is trying
harder, but it was not there.

My recommendation here is the same as for the optimization level: Try
to stick with what most people are using.  If, say, some Linux
distribution switched all their builds to use LTO, then ok.  But
otherwise, you don't want to be the only one running a particular
configuration in production.
