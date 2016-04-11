---
layout: post
title: "Some git log tweaks"
date: 2016-04-11 08:00:00 -0400
comments: true
categories:
- git
- planet debian
---

Here are some tweaks to `git log` that I have found useful.  It might
depend on the workflow of individual projects how applicable this is.

Git stores separate author and committer information for each commit.
How these are generated and updated is sometimes mysterious but
generally makes sense.  For example, if you cherry-pick a commit to a
different branch, the author information stays the same but the
committer information is updated.  `git log` defaults to showing the
author information.  But I generally care less about that than the
committer information, because I'm usually interested in when the
commit arrived in my or the public repository, not when it was
initially thought about.  So let's try to change the default `git log`
format to show the committer information instead.  Again, depending on
the project and the workflow, there can be other preferences.

To create a different default format for `git log`, first create a new
format by setting the Git configuration item `pretty.somename`.  I
chose `pretty.cmedium` because it's almost the same as the default
`medium` but with the author information replaced by the committer
information.

```
[pretty]
cmedium="format:%C(auto,yellow)commit %H%C(auto,reset)%nCommit:     %cn <%ce>%nCommitDate: %cd%n%n%w(0,4,4)%s%n%+b"
```

Unfortunately, the default `git log` formats are not defined in terms
of these placeholders but are hardcoded in the source, so this is my
best reconstruction using the available means.

You can use this as `git log --pretty=cmedium`, and you can set this
as the default using

```
[format]
pretty=cmedium
```

If you find this useful and you're the sort of person who is more
interested in their own timeline than the author's history, you might
also like two more tweaks.

First, add `%cr` for relative date, so it looks like

```
[pretty]
cmedium="format:%C(auto,yellow)commit %H%C(auto,reset)%nCommit:     %cn <%ce>%nCommitDate: %cd (%cr)%n%n%w(0,4,4)%s%n%+b"
```

This adds a relative designation like "2 days ago" to the commit date.

Second, set

```
[log]
date=local
```

to have all timestamps converted to your local time.

When you put all this together, you turn this

    commit e2c117a28f767c9756d2d620929b37651dbe43d1
    Author: Paul Eggert <eggert@cs.ucla.edu>
    Date:   Tue Apr 5 08:16:01 2016 -0700

into this

    commit e2c117a28f767c9756d2d620929b37651dbe43d1
    Commit:     Paul Eggert <eggert@cs.ucla.edu>
    CommitDate: Tue Apr 5 11:16:01 2016 (3 days ago)

PS: If this is lame, there is always this:
http://fredkschott.com/post/2014/02/git-log-is-so-2005/
