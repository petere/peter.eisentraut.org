---
layout: post
title: "Using GNU GLOBAL with PostgreSQL"
date: 2016-07-20 08:00:00 -0400
comments: true
tags:
- global
- gnu
- postgresql
---

When you are coding in a source tree as big as PostgreSQL’s, you will
at some point want to look into some kind of source code indexing.
It’s often convenient not to bother, since `git grep` is actually
superfast.  But when you want to find where a function is defined
among all the call sites, some more intelligence is useful.

The traditional tools for this are `ctags` and `etags`, which create
index files intended for use by vi and Emacs, respectively.  The
PostgreSQL source tree has some customized support for these in the
tools `src/tools/make_ctags` and `src/tools/make_etags`.  Because
these tools operate on a directory level, those wrapper scripts create
a single tag file (named `tags` or `TAGS` respectively) in the
top-level directory and symlink it to all the other directories.  This
allows you to easily look for entries across the entire source tree.
But it’s clearly a hack, and at least Emacs is often somewhat confused
by this setup.

But there is something much better that works very similarly:
[GNU GLOBAL](https://www.gnu.org/software/global/).  A main difference
is that GNU GLOBAL works on a project basis not on a directory basis,
so you don’t need to do contortions to create and manage tags files
all over your source tree.  Also, GLOBAL can be used from the command
line, so you don’t need to be an editor wizard to get started with it.
Plus, it appears to be much faster.

The whole thing is very simple. Install the package, which is usually
called `global` and available in most operating system distributions.
To start, run

    $ gtags

in the top-level directory.  This creates the files `GPATH`, `GRTAGS`,
and `GTAGS`.

Then you can use `global` to search for stuff, like

    $ global elog
    src/include/utils/elog.h

Or you can look for places a function is called:

    $ global -r write_stderr

You can run `global` in any directory.

Or how about you want to look at the code where something is defined:

    $ less -t elog

Note no file name is required.  (See the manual for the required setup
to make this work with `less`.)

Or of course use editor integration.  For Emacs, there is
`ggtags-mode`.

Here is some fine-tuning for use with the PostgreSQL source tree.
Generally, I don’t want to index generated files.  For example, I
don’t want to see hits in `gram.c`, only in `gram.y`.  Plus, you don’t
want to index header files under `tmp_install`.  (Super annoying when
you use this to jump to a file to edit and later find that your edits
have been blown away by `make check`.)  But when you run `gtags` in a
partially built tree, it will index everything it finds.  To fix that,
I have restricted `gtags` to only index files that are registered in
Git, by first running

    git ls-files >gtags.files

in the top-level directory.  Then `gtags` will only consider the
listed files.

This will also improve the workings of the Emacs mode, which will at
random times call `global -u` to update the tags.  If it finds a
`gtags.files` file, it will observe that and not index random files
lying around.

I have a shell alias `pgconfigure` which calls `configure` with a
bunch of options for easier typing.  It’s basically something like

```sh
pgconfigure() {
    ./configure --prefix=$(cd .. && pwd)/pg-install --enable-debug --enable-cassert ...
}
```

At the end I call

```sh
git ls-files >gtags.files
gtags -i &
```

to initialize the source tree for GNU GLOBAL, so it’s always
there.
