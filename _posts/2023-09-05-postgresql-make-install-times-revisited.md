---
title: "PostgreSQL make install times revisited"
comments: true
tags:
- meson
- postgresql
---

We continue our exploration of PostgreSQL build system performance.  A
long time ago, I wrote an
[article](https://petereisentraut.blogspot.com/2012/03/postgresql-make-install-times.html)
about how to optimize the performance of `make install`.  This was
quite helpful, as it reduced the time from 10.493 s by default to
1.654 s with some tweaks (6x faster).  Now, with different hardware, a
much newer PostgreSQL, and a new build system looming, let's take
another look.

First, let's check the time for a standard `make install` run and then
how the optimizations suggested in the old article work.

| Command                             | macOS 13 | Ubunty 22.04 |
|-------------------------------------|----------|--------------|
| `make install`                      | 2.384 s  | 1.472 s      |
| `make install enable_nls=no`        | 1.634 s  | 1.090 s      |
| `make install -s`                   | 2.342 s  | 1.326 s      |
| `make install -jN`                  | 0.984 s  | 0.666 s      |
| `make install enable_nls=no -s -jN` | 0.784 s  | 0.464 s      |

Ok, the default is already much better than in the olden days.  But
with some additional techniques applied it's still 3x faster!

There are two tricks suggested in the old article that I did not show
here: First, it suggested using dash instead of the default shell bash
at the time.  The Ubuntu system used here already uses dash by
default.  I tried dash on the macOS system, but it performed much
worse (weird?).  Second, the old article suggested overriding the
`install` program.  That information is obsolete, because `configure`
has been changed — in response to that article — to pick up an
available `install` program automatically (commit
[9db7ccae20](https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=9db7ccae20)).

Now, in order to compare this to Meson below, we need to check `make
install-world-bin`, so that we install the same set of files.  So
let's get some baselines with that command.

| Command                                       | macOS 13 | Ubunty 22.04 |
|-----------------------------------------------|----------|--------------|
| `make install-world-bin`                      | 2.905 s  | 1.806 s      |
| `make install-world-bin enable_nls=no -s -jN` | 0.857 s  | 0.542 s      |

So, all the tricks applied get about the same (or even better than) 3x
improvement.

## Meson

Now let's look at Meson:

| Command                                                                  | macOS 13 | Ubunty 22.04 |
|--------------------------------------------------------------------------|----------|--------------|
| `meson install`                                                          | 2.822 s  | 0.556 s      |
| `meson install` with `-Dnls=disabled`                                    | 2.734 s  | 0.424 s      |
| `meson install --quiet`                                                  | 2.734 s  | 0.369 s      |
| `meson install --quiet --no-rebuild`                                     | 2.565 s  | 0.306 s      |
| `meson install --quiet --only-changed`                                   | 0.489 s  | 0.243 s      |
| `meson install --quiet --only-changed --no-rebuild` and `-Dnls=disabled` | 0.347 s  | 0.177 s      |

Here, there is also a 3x improvement on Ubuntu and up to 8x
improvement on macOS.

Some of the available options are different for Meson than for make.
Meson doesn't have an option to run the installation parallelized.
(Note that here, it is really Meson doing the installation.  Ninja is
not involved.  You can call `ninja install`, but it will just call
`meson install`.)  This is unfortunate, but it appears that some of
the other options can make up for that a bit.

Recall that the installation time is that interesting because the
installation is run during the test suite to create a temporary
installation.  This happens even if you run a small and fast test
(say, you only want to run the `pg_basebackup` test suite).  For that
use, the `--no-rebuild` option is useful, because `meson test` already
did the rebuild (unless you did `meson test -no-rebuild`!), and so
`meson install` doesn't need to try it again.  And the
`--only-changed` option is useful in that case because you know that
the previous files in the temporary installation are from your own
previous test runs, so you can trust them to be reliable and keep them
if they are up to date.  As you can see, skipping these extra copies
can save a lot of time on some platforms.  So these two options are
mainly useful for developers in controlled circumstances, but probably
not for production installations or packaging.  Note that in the
current code, the test setup runs `meson install` with exactly these
options, so this is already taken care of.  But it's also useful to
use them manually if you are testing with an external installation.

Some conclusions:

* Using some of the additional `make install` or `meson install`
  option is still useful to get better performance, but some of the
  previous tricks are thankfully no longer necessary.

* If you use Meson and run the tests through Meson, you already get
  most of the advantages automatically.

* Linux appears to be faster than macOS for this.  (We had already
  observed something similar [before]({% post_url
  2023-06-28-postgresql-compile-times-meson-review %}).)

---
Details on tests setup:

* Tests where run on tag `REL_16_RC1`.

* `configure` command line: `./configure --prefix=somewhere --enable-nls`

* `meson` command line: `meson setup --auto-features=disabled -Dnls=enabled --prefix=somewhere`

* Parallelism was `-j12` on macOS and `-j4` on Ubuntu.  I just took
  the number of CPU cores.  There were clearly diminishing returns
  past a certain number.
