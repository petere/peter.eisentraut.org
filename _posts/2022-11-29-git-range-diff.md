---
layout: post
title: "git range-diff"
comments: true
tags:
- git
- postgresql
---

Let's say you are following a patch in the PostgreSQL [commit
fest](https://commitfest.postgresql.org/).  The author has posted "v5"
of a patch, some feedback has been sent, the author comes back with
"v6" and a note saying that they have incorporated all that feedback.
How do you check what actually changed?

A straightforward way is to make two separate branches in your local
Git repository, commit the two patches, and compare the results,
perhaps like this:

	git checkout -b tmp5 master
	git am v5-0001-My-feature.patch
	git checkout -b tmp6 master
	git am v6-0001-My-feature.patch
	git diff tmp5 tmp6

This works in simple cases.  It will not work if the patch is actually
a patch series (0001, 0002, ...).  Then this recipe will just show you
the difference between all patches applied, which is still ok, but it
defeats the point of organizing the changes into separate patches.
Another issue is that maybe the old patch does not apply anymore on
the same base revision.  Maybe the reason v6 was sent is because v5
didn't apply anymore.  If v6 contains both review-based changes and
conflict resolutions, then things get really complicated.  If you just
`git diff tmp5 tmp6`, your diff includes everything that has changed
in `master` since the v5 patch applied cleanly, which is probably
useless.

You can get adventurous and just diff the actual patch files:

	diff -u v5-0001-My-feature.patch v6-0001-My-feature.patch

There is also a program called `interdiff` (part of
[patchutils](http://cyberelk.net/tim/software/patchutils/)) that can
help with that.

This can work in a bind, but again, if it's a patch series, it won't
work well, or you have to do a lot of manual work.

Git has a lesser known command that can help with this: [`git
range-diff`](https://git-scm.com/docs/git-range-diff).  To use it,
apply the patch series to separate branches, as shown above, and then
run

	git range-diff master tmp5 tmp6

The output format is naturally complex.  I'm not going to try to
explain it here; check the documentation and try it for yourself.

To try this out, I dug up a patch of mine from a few months ago.  From
[this
thread](https://www.postgresql.org/message-id/flat/8528fb7e-0aa2-6b54-85fb-0c0886dbd6ed@enterprisedb.com),
I downloaded the v4 and v5 patches.  v4 was two patches, v5 was only
one since the first one had been applied in the meantime.  `git
range-diff` can recognize this and will match up the
`v4-0002-....patch` with the `v5-0001-....patch`!  Here is what I did:

	git checkout -b tmp4 'master@{2022-08-30 18:15:40}'
	git am v4-000*.patch
	git checkout -b tmp5 'master@{2022-09-08 09:26:06}'
	git am v5-000*.patch
	git range-diff tmp4~~..tmp4 tmp5~..tmp5

The output of this indicates that the first patch was not present in
the second patch series, and that there was a small change in the
patch common to both series.  Useful!

Note that in this example I used the `master@{date}` notation to get
to the master branch as of when the patch was posted (per email
archive).  This is assuming that there wasn't too much of a gap
between making the patch and posting it.  This can be made more exact
if the patch author uses the `git format-patch --base` option, which
embeds the base commit into the patch, for future reference like this.

`git range-diff` has its own mini syntax for specifying the ranges.
In the first example, the two branches had the same base commit, so a
simplified syntax could be used.  In the second example, I specified
the ranges explicitly.  There is also a three-dot syntax variant, but
I haven't figured out when that would be useful.  (You might find my
[previous
post](https://peter.eisentraut.org/blog/2022/09/13/git-diff-and-git-log-and-dots)
on three-dot syntax in Git interesting.)
