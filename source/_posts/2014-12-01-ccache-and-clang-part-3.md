---
layout: post
title: "ccache and clang, part 3"
date: 2014-12-01 20:00:00 -0500
comments: true
categories:
- ccache
- clang
- planet debian
- planet postgresql
---

In
[part 1](http://petereisentraut.blogspot.com/2011/05/ccache-and-clang.html)
and
[part 2](http://petereisentraut.blogspot.com/2011/09/ccache-and-clang-part-2.html)
I investigated how to use `ccache` with `clang`.  That was more than
three years ago.

I got an email the other day that
[ccache bug 8118](https://bugzilla.samba.org/show_bug.cgi?id=8118),
which I filed while writing part 1, was closed, as ccache 3.2 was
released.  The
[release notes of clang 3.2](https://ccache.samba.org/releasenotes.html#_ccache_3_2)
contain several items related to clang.  So it was time to give this
another look.

Basically, the conclusions from part 2 still stand: You cannot use
`ccache` with `clang` without using `CCACHE_CPP2`.  And it is now
becoming clear to me that this is an issue that is not going to go
away, and it's not really even Clang's fault.

## Warnings!

The problem is that `clang`'s `-Wall` can cause warnings when
compiling the *preprocessed* version of otherwise harmless C code.
This can be illustrated by this piece of C code:

```c
int
foo()
{
        int *p, *q;

        p = q = 0;
        p = p;
        if (p == p)
                return 1;
        if ((p == q))
                return 2;
        return 0;
}
```

When compiled by `gcc-4.9 -Wall`, this gives no warnings.  When
compiled by `clang-3.5 -Wall`, this results in
```
test.c:7:4: warning: explicitly assigning value of variable of type 'int *' to itself [-Wself-assign]
test.c:8:8: warning: self-comparison always evaluates to true [-Wtautological-compare]
test.c:10:9: warning: equality comparison with extraneous parentheses [-Wparentheses-equality]
test.c:10:9: note: remove extraneous parentheses around the comparison to silence this warning
test1.c:10:9: note: use '=' to turn this equality comparison into an assignment
```

You wouldn't normally write code like this, but the C preprocessor
could create code with self-assignments, self-comparisons, extra
parentheses, and so on.

This example represents the issues I saw when trying to compile
PostgreSQL 9.4 with `ccache` and `clang`; there might be others.

You can address this issue in two ways:

1. Use `CCACHE_CPP2`, as discussed in part 2.  With ccache 3.2, you
can now also put this into a configuration file: `run_second_cpp =
true` in `~/.ccache/ccache.conf`

2. Turn off the warnings mentioned above: `-Wno-parentheses-equality`,
`-Wno-tautological-compare`, `-Wno-self-assign` (and any others you
might find).  One might think that these are actually useful warnings
that one might want to keep, but GCC doesn't warn about them, and if
you develop primarily with GCC, your code might contain these issues
anyway.  In particular, I have found that `-Wno-tautological-compare`
is necessary for legitimate code.

I think `CCACHE_CPP2` is the way to go, for two reasons.  Firstly,
having to add more and more options to turn off warnings is obviously
somewhat stupid.  Secondly and more importantly, there is nothing
stopping GCC from adding warnings similar to Clang's that would
trigger on preprocessed versions of otherwise harmless C code.  Unless
they come up with a clever way to annotate the preprocessed code to
the effect of "this code might look wrong to you, but it looked OK
before preprocessing, so don't warn about it", in a way that creates
*no* extra warnings and doesn't lose *any* warnings, I don't think
this issue can be solved.

## Speed!

Now the question is, how much would globally setting `CCACHE_CPP2`
slow things down?

To test this, I have built PostgreSQL 9.4rc1 with `clang-3.5` and
`gcc-4.8` (not `gcc-4.9` because it creates some unrelated warnings
that I don't want to deal with here).  I have set `export
CCACHE_RECACHE=true` so that the cache is not read but new cache
entries are computed.  That way, the overhead of `ccache` on top of
the compiler is measured.

Results:

- `clang-3.5`
    - Using `ccache` is 10% slower than not using it at all.
    - Using `ccache` with `CCACHE_CPP2` on is another 10% slower.
- `gcc-4.8`
    - Using `ccache` is 19% slower than not using it at all.
    - Using `ccache` with `CCACHE_CPP2` is another 9% slower.

(There different percentages between `gcc` and `clang` arise because
`gcc` is faster than `clang` (yes, really, more on that in a future
post), but the overhead of `ccache` doesn't change.)

10% or so is not to be dismissed, but let's remember that this applies
only if there is a cache miss.  If everything is cached, both methods
do the same thing.  Also, if you use parallel make, the overhead is
divided by the number of parallel jobs.

With that in mind, I have decided to put the issue to rest for myself
and have made myself a `~/.ccache/ccache.conf` containing

    run_second_cpp = true

Now Clang or any other compiler should run without problems through
ccache.

## Color!

There is one more piece of news in the new ccache release: Another
thing I talked about in part 1 was that `ccache` will disable the
colored output of `clang`, and I suggested workarounds.  This was
actually fixed in ccache 3.2, so the workarounds are no longer
necessary, and the above configuration change is really the only thing
to make Clang work smoothly with ccache.
