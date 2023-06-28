---
title: "PostgreSQL compile times: Meson review"
comments: true
tags:
- meson
- postgresql
---

In a recent [article]({% post_url 2023-05-29-postgresql-compile-times
%}), I compared the compilation times of PostgreSQL using different
compilers.  In the comments, I was asked for numbers for the new Meson
build machinery.  Let's do that now.

(Of course, when we are testing the compilation step, we are not
really using Meson much but rather Ninja operating on build
description files produced by Meson.)

We have to consider how we can make both build systems build
approximately the same set of files, to make this a fair comparison.
I'm going to use `make world-bin` on the make side, which builds the
same things as `meson compile` on the meson side (that is, core,
contrib, but not documentation).  Also, I'm configuring with plain
`configure` without options and with `meson setup
--auto-features=disabled`, in order to get approximately the same
build configuration.  Finally, I'm running the `configure` and `make`
build in a separate build directory, to match the meson build, just in
case that matters.  Beyond that, the methodology is the same as in the
previous article.

First, while we're here, let's time the initial configure/setup step:

| OS           | Compiler    | configure | meson setup |
|--------------|-------------|-----------|-------------|
| macOS 13     | Apple clang | 13.207    | 7.041       |
| Ubuntu 22.04 | gcc-12      | 6.942     | 4.215       |

This surprised me a bit, because it didn't feel that `meson setup` was
all that fast, but it's good to know.  (Actually, a significant chunk
of the `configure` slowness is the preparation of the separate build
directory.)

Now to time the builds.  Build everything serially:

| OS           | Compiler    | make -s world-bin | meson compile -j 1 |
|--------------|-------------|-------------------|--------------------|
| macOS 13     | Apple clang | 2:03.60           | 2:23.84            |
| Ubuntu 22.04 | gcc-12      | 3:06.51           | 3:45.61            |

So meson/ninja appear to be a bit slower here.  (I strongly suspect
that this is not because, like, ninja is slower, but instead because
internally it builds more intermediate steps somehow.  But in any
case, this is the end result.)

Build everything in parallel:

| OS           | Compiler    | make -s world-bin -j _N_ | meson compile -j _N_ |
|--------------|-------------|--------------------------|----------------------|
| macOS 13     | Apple clang | 27.877                   | 26.554               |
| Ubuntu 22.04 | gcc-12      | 59.106                   | 1:03.214             |

(For macOS, I used _N_ = 8, which is where parallelism plateaued in
the last test.  For Ubuntu, I used _N_ = 4, because that's how many
CPUs that VM had.)

I would say inconclusive, but the parallelism appears to eliminate
some of the disadvantage that meson/ninja had in the serial test.

Build everything in parallel when everything is already up to date:

| OS           | Compiler    | make -s world-bin -j _N_ | meson compile -j _N_ |
|--------------|-------------|--------------------------|----------------------|
| macOS 13     | Apple clang | 0.400                    | 0.405                |
| Ubuntu 22.04 | gcc-12      | 0.352                    | 0.186                |

About the same, I guess.

The above was all with ccache disabled.  Now build everything in
parallel with ccache (fully cached):

| OS           | Compiler    | make -s world-bin -j _N_ | meson compile -j _N_ |
|--------------|-------------|--------------------------|----------------------|
| macOS 13     | Apple clang | 6.707                    | 5.705                |
| Ubuntu 22.04 | gcc-12      | 4.959                    | 4.720                |

This is different from the case where everything is up to date.  If
everything is up to date, only make and ninja have to do work, to
check that.  But here, make and ninja still have to run all the
compiler commands, but the compiler commands themselves do almost
nothing.  So that is testing mainly the efficiency of make vs. ninja,
and you'd expect ninja to win this, because it was explicitly designed
to be better at this.

Some conclusions:

* Apart from the initial configure/setup step, meson/ninja don't
  consistently save anything over configure/make.

* Linux appears to have a systematic advantage over macOS in certain
  tasks.
