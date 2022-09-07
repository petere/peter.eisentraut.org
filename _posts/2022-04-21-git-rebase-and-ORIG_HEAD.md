---
layout: post
title: "git rebase and ORIG_HEAD"
comments: true
tags:
- git
---

I seem to be doing this a lot:

	$ git branch --show-current
	master
	$ git checkout my-feature-branch
	$ git rebase master

Except that `master` might be another main branch.  There should be a
way to just say, “rebase on whatever I had previously checked out”.
In some contexts, `ORIG_HEAD` points to what the `HEAD` was
previously, for some definition of previously.  It appears that `git
checkout` sets `ORIG_HEAD`, but I haven’t found any documentation on
this nor have been able to trace this in the git source code.  But it
appears to work.  So it would be:

	git checkout master
	git pull
	git checkout my-feature-branch
	git rebase ORIG_HEAD

It would be nice if `ORIG_HEAD` had a shortcut like `@` for `HEAD`.
Something to think about.
