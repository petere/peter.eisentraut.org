---
layout: post
title: "Checking whitespace with Git"
date: 2014-11-04 20:00:00 -0500
comments: true
categories:
- git
- planet debian
- planet postgresql
---
[Whitespace matters](http://blog.codinghorror.com/whitespace-the-silent-killer/).

Git has support for checking whitespace in patches.  `git apply` and `git am` have the option `--whitespace`, which can be used to warn or error about whitespace errors in the patches about to be applied. `git diff` has the option `--check` to check a change for whitespace errors.

But all this assumes that your existing code is cool, and only new changes are candidates for problems.  Curiously, it is a bit hard to use those same tools for going back and checking whether an existing tree satisfies the whitespace rules applied to new patches.

The core of the whitespace checking is in `git diff-tree`.  With the `--check` option, you can check the whitespace in the diff between two objects.

But how do you check the whitespace of a tree rather than a diff?  Basically, you want

    git diff-tree --check EMPTY HEAD

except there is no `EMPTY`.  But you can compute the hash of an empty Git tree:

    git hash-object -t tree /dev/null

So the full command is

    git diff-tree --check $(git hash-object -t tree /dev/null) HEAD

If have this as an alias in my `~/.gitconfig`:

    [alias]
        check-whitespace = !git diff-tree --check $(git hash-object -t tree /dev/null) HEAD

Then running

    git check-whitespace

can be as easy as running `make` or `git commit`.
