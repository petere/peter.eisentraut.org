---
title: "PostgreSQL compile times"
comments: true
tags:
- gcc
- clang
- postgresql
---

What's the fastest compiler for PostgreSQL?  Let's take a look.

|--------------|------------------|--------------|
| OS           | Compiler         | time make -s |
|--------------|------------------|--------------|
| macOS 13     | gcc-13           | 3:59.29      |
|              | gcc-12           | 3:42.19      |
|              | gcc-11           | 3:33.35      |
|              | clang-16         | 3:05.05      |
|              | clang-15         | 2:19.71      |
|              | clang-14         | 2:21.03      |
|              | clang-13         | 2:20.72      |
|              | Apple clang (14) | **1:55.87**  |
| Ubuntu 22.04 | gcc-12 (default) | 2:57.87      |
|              | gcc-11           | 2:24.20      |
|              | gcc-10           | **2:18.28**  |
|              | clang-15         | 2:21.62      |
|              | clang-14         | 2:24.23      |
|              | clang-13         | 2:25.68      |

Compilers keep getting slower, it appears!  Maybe don't use the latest
one right away!

Also, gcc vs clang?  Not sure, it depends.

The above uses the default optimization level -O2.  Let's see if we
can squeeze out more:

| Optimization | Apple clang | gcc-13  |
|--------------|-------------|---------|
| -O3          | 1:55.10     | 4:26.59 |
| -O2          | 1:52.13     | 4:08.09 |
| -Og          | 1:49.22     | 2:46.33 |
| -O1          | 1:48.15     | 3:07.30 |
| -Os          | 1:49.47     | 3:36.30 |
| -Oz          | 1:44.37     | 3:36.18 |
| -O0          | 1:07.65     | 2:29.51 |

So on the clang side, to get any real benefit, you need to go all the
way to -O0, which I don't recommend for general use, because then you
don't get many of the helpful compiler warnings.  On the gcc side, it
might be beneficial to use one of the intermediate levels to get
better performance.

Let's also test how well parallelism works:

| Parallelism    | Apple clang | gcc-13  |
|----------------|-------------|---------|
| -j1            | 1:55.87     | 4:09.10 |
| -j2            | 1:02.33     | 2:11.77 |
| -j3            | 46.261      | 1:36.65 |
| -j4            | 38.298      | 1:19.08 |
| -j5            | 34.003      | 1:07.55 |
| -j6            | 30.118      | 1:00.89 |
| -j7            | 27.844      | 56.712  |
| -j8            | 25.857      | 51.929  |
| -j9            | 25.502      | 50.734  |
| -j10           | 25.046      | 49.071  |
| -j11           | 24.778      | 50.758  |
| -j12           | 24.358      | 48.825  |
| -j13           | 24.571      | 48.655  |
| -j (unlimited) | 26.891      | 1:00.23 |

The arithmetic here is unsurprising up to a point.  This machine has
12 CPU cores, so you get speedups until around -j12.  But it's notable
that the gains level off at 8.  It could be because there are 8&nbsp;"performance" cores and 4 "efficiency" cores, and the efficiency cores
aren't that helpful for this?  Or maybe because there is just not that
much more parallelism to be had in the build.

So, to conclude, there is a large range in the time measurements here.
You can go from more than 4&nbsp;minutes for a build to about
25&nbsp;seconds with the right choice of compiler and build options.
Obviously, the absolute numbers will vary for everyone depending on
the hardware and available software.  But it's worth exploring!

Of course, there are several other components that affect build and
test cycle performance, including ccache, configure vs. meson, make
vs. ninja, choice of linker, PostgreSQL build options, and so on.
More articles to come.

---

Details on the methodology:

* All tests in this article were done on tag `REL_16_BETA1`.

* Ccache was disabled by `export CCACHE_DISABLE=1`.

* Timings were done like this: `git clean -fdx; ./configure CC=xxx; time make -s`
