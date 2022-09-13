---
layout: post
title: "git diff and git log and dots"
comments: true
tags:
- git
- postgresql
---

A little while ago, we had a few PostgreSQL hackers in a room and
someone oversaw me typing something like

	git diff REL_14_STABLE...REL_15_STABLE

and they wondered, "oh, I didn't know about three dots".  My flippant
explanation was, "you use three dots when two dots don't give you the
right answer".

But let's unpack this.

This

	git diff REL_14_STABLE REL_15_STABLE

gives you the complete difference between (the tip of) PostgreSQL 14
and PostgreSQL 15.  This will be a huge diff.

This diff does not include changes that were made on both
`REL_14_STABLE` and `REL_15_STABLE`.  For example,
[`b9b21acc766db54d8c337d508d0fe2f5bf2daab0`](https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=b9b21acc766db54d8c337d508d0fe2f5bf2daab0)
was backpatched to both branches, so it doesn't show up in the above
diff at all.

This is almost never what you want when looking at diverging stable
branches like this.  It might make sense to look at the cross-version
diff of a particular file, perhaps, like this:

	git diff REL_14_STABLE REL_15_STABLE -- src/test/regress/parallel_schedule

But the full diff is usually not useful, at least for manual inspection.

Then there is

	git diff REL_14_STABLE..REL_15_STABLE

This is exactly the same as the above command without the dots.  The
two forms are equivalent.

So now let's look at the three dots:

	git diff REL_14_STABLE...REL_15_STABLE

The [`git-diff` documentation](https://git-scm.com/docs/git-diff) says
that this is equivalent to `git diff $(git merge-base REL_14_STABLE
REL_15_STABLE) REL_15_STABLE`.  The result of that `git merge-base`
is:

	$ git merge-base REL_14_STABLE REL_15_STABLE
	e1c1c30f635390b6a3ae4993e8cac213a33e6e3f

So the original command is equivalent to

	git diff e1c1c30f635390b6a3ae4993e8cac213a33e6e3f REL_15_STABLE

So what is the point of that? Note that the commit immediately after
[`e1c1c30f635390b6a3ae4993e8cac213a33e6e3f`](https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=e1c1c30f635390b6a3ae4993e8cac213a33e6e3f)
on branch `REL_15_STABLE`
[is](https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=596b5af1d3675b58d4018acd64217e2f627da3e4)

	commit 596b5af1d3675b58d4018acd64217e2f627da3e4
	Author: Andrew Dunstan <andrew@dunslane.net>
	Date:   Mon Jun 28 17:31:16 2021

	Stamp HEAD as 15devel.

	Let the hacking begin ...

So `e1c1c30f635390b6a3ae4993e8cac213a33e6e3f` is the last commit that
`REL_14_STABLE` and `REL_15_STABLE` had in common.  (That's what Git
calls the "merge base", although no merging is taking place here.  But
it would be relevant if you wanted to merge those two branches
together.)

So the three-dot variant `git diff REL_14_STABLE...REL_15_STABLE`
gives you "everything in `REL_15_STABLE` since it was branched off
`REL_14_STABLE`", which is essentially, "everything that is new in
`REL_15_STABLE`" (save patches that were backpatched to both), which
is almost always what I want.

Note that this diff includes the [backpatched
version](https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=cc7e0feba51b4aeb0adf9bdac659f83e9986b90d)
of commit `b9b21acc766db54d8c337d508d0fe2f5bf2daab0` mentioned above,
since it is new in `REL_15_STABLE` since it was branched off, even
though it is not different between `REL_14_STABLE` and
`REL_15_STABLE`.

By the way, an equivalent form is

	git diff --merge-base REL_14_STABLE REL_15_STABLE

I have never used that, since it's a bit much too type, but it's
there.

* * *

Then there is `git log`, which has similar considerations, except they
are different.

The [documentation of `git log`](https://git-scm.com/docs/git-log)
says, "[l]ists commits that are reachable by following the parent
links from the given commit(s)".  So,

	git log REL_15_STABLE

lists all commits from the current `REL_15_STABLE` back to the
beginning of time.  Then,

	git log REL_14_STABLE REL_15_STABLE  # WRONG!

lists all commits from the current `REL_14_STABLE` _and_
`REL_15_STABLE` back to the beginning of time.  The commits are in
reverse chronological order by default, so this will actually show the
commits from both branches mixed together.  For example, the
`REL_15_STABLE` version of our backpatched commit
`b9b21acc766db54d8c337d508d0fe2f5bf2daab0` from above is shown right
next to its equivalent commit in `REL_14_STABLE`.  So if you're ever
"seeing double" in `git log`, you might have gotten this wrong.

The documentation of `git-log` goes on to say, "but exclude commits
that are reachable from the one(s) given with a ^ in front of them".
So are more sensible construction would be

	git log REL_15_STABLE ^REL_14_STABLE

This gives you all the commits up to `REL_15_STABLE` from the
beginning of time, except the ones already included in
`REL_14_STABLE`.  This is effectively everything that is in
`REL_15_STABLE` since it was branched from `REL_14_STABLE`.  The last
commit shown will be the "Let the hacking begin" one.

The above can also be written in this equivalent, more familiar form:

	git log REL_14_STABLE..REL_15_STABLE

Now, `git log` also has a three-dot form:

	git log REL_14_STABLE...REL_15_STABLE

Per its documentation, this is equivalent to

	git log REL_14_STABLE REL_15_STABLE --not $(git merge-base --all REL_14_STABLE REL_15_STABLE)

which is

	git log REL_14_STABLE REL_15_STABLE ^e1c1c30f635390b6a3ae4993e8cac213a33e6e3f

This will give you the same mixed list of commits from `REL_14_STABLE`
and `REL_15_STABLE` mentioned above, but it will stop at the branch
point instead of going back to the beginning of time.  I don't know
when this is useful.

* * *

So, to summarize:

* `git diff`: use three dots
* `git log`: use two dots

Or go with my original approach: Use three dots when two dots don't
give you the right answer (and vice versa).
