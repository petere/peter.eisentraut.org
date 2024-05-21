---
title: "New compilers, new timings"
comments: true
tags:
- clang
- gcc
- postgresql
---

I had been eagerly awaiting the releases of [Clang
18](https://releases.llvm.org/18.1.0/tools/clang/docs/ReleaseNotes.html)
and [GCC 14](https://gcc.gnu.org/gcc-14/) for the last few weeks.  Now
that they are both out, I figured I would check how fast they are for
compiling PostgreSQL.

(The actual reasons why I was awaiting these compiler releases are
related to the warning option
[`-Wmissing-variable-declarations`](https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html#index-Wmissing-variable-declarations).
GCC 14 now supports this option and PostgreSQL might want to [use
it](https://www.postgresql.org/message-id/flat/e0a62134-83da-4ba4-8cdb-ceb0111c95ce@eisentraut.org).
On the Clang side, the new release of LLVM enables a new release of
IWYU that handles global variable declarations
[correctly](https://github.com/include-what-you-use/include-what-you-use/issues/1461).)

For the speed tests, I'm reusing the methodology from my previous
articles about this last year ([here]({% post_url
2023-05-29-postgresql-compile-times %}) and [here]({% post_url
2023-06-28-postgresql-compile-times-meson-review %})).  The host
machine has been upgraded over time in various ways, so the timings
are not necessarily comparable across these articles.  The tests are
done on tag `REL_16_3` this time.

| OS       | Compiler         | time meson compile -j1 |
|----------|------------------|------------------------|
| macOS 14 | gcc-14           | 4:57.73                |
|          | gcc-13           | 4:45.41                |
|          | gcc-12           | 4:30.17                |
|          | clang-18         | 2:18.10                |
|          | clang-17         | 4:22.19                |
|          | clang-16         | 4:00.87                |
|          | clang-15         | 2:56.41                |
|          | Apple clang (15) | 2:18.48                |

Observations:

* GCC is getting progressively slower with every release, continuing
  the trend already noticeable [last year]({% post_url
  2023-05-29-postgresql-compile-times %}).

* Clang had some trouble with versions 16 and 17, but it turned out
  that this was a [compiler
  bug](https://www.postgresql.org/message-id/flat/CAGECzQQg4qmGbqqLbK9yyReWd1g%3Dd7T07_gua%2BRKXsdsW9BG-Q%40mail.gmail.com)
  triggered by a specific file in PostgreSQL.  This was apparently
  fixed in version 18, and now the compile performance is better than
  version 15 even.

* Normal Clang has now reached parity with Apple Clang, which was
  previously mysteriously significantly faster.

The above tests were intentionally done with -j1, but just for
illustration I also ran a few tests with -j8:

| OS       | Compiler | time meson compile -j8 |
|----------|----------|------------------------|
| macOS 14 | gcc-14   | 44.577 s               |
|          | clang-18 | 20.021 s               |

This shows that this scales pretty well linearly.

Clang 18 is now, on this platform, clearly the best choice.[^warnings]
Roughly twice as fast as GCC 14!

[^warnings]: I had in the past been hesitant to switch to Clang
    completely because I was worried that Clang would issue different
    kinds of compiler warnings and I would end up producing code that
    compiled without warnings on Clang but might produce warnings on
    GCC that everybody else was using.  After investigating this, if
    you switch from GCC 14 to Clang 18, you lose this two warnings:
    `-Wimplicit-fallthrough=3 -Wshadow=compatible-local`.  That seems
    tolerable.
