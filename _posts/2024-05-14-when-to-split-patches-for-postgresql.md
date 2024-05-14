---
title: "When to split patches for PostgreSQL"
comments: true
tags:
- postgresql
---

In my previous article on [how to submit patches by email]({% post_url
2023-05-09-how-to-submit-a-patch-by-email-2023-edition %}) for
PostgreSQL, I skipped over whether patches should be split up.  Let's
discuss that now.

(See the previous article, as well as general Git documentation, for
the technical details of _how_ to split up a patch.  Here, I'm only
talking about _why_.)

What I'm talking about here specifically is where instead of attaching
one patch to an email to
[pgsql-hackers](https://www.postgresql.org/list/pgsql-hackers/), you
attach a sequence of patch files like `0001-first.patch`,
`0002-second.patch`, etc. (see previous article for the correct
naming).

What follows is my opinion, based on what I like to see during patch
reviews, and how I tend to prepare my patch submissions.  Maybe it's
all wrong and others hate it and wish I'd stop it.  Feedback welcome.
But anyway.

The foremost principle is, each patch in a series should make sense on
its own, and it should move the source tree from one working state to
another working state. (Think of the "C" in ACID.)  When I review a
patch series, I review each patch separately, and I also run each
patch (incrementally on top of its predecessors) through the test
suites.  If that fails, meh.

This principle can be applied and interpreted in different ways, and
that's fine.  Let's go through a few different cases:

_[I will show some examples.  In order not to pick on anyone else, I'm
only picking examples that I authored or I'm otherwise closely
involved in.]_

1. Simplest case: You send the whole thing as one patch.  Nothing
   wrong with that, let's be clear.  Start here if you don't know
   better or you're not a Git wizard or none of the other cases apply.
   There appears to be a natural limit on how [big a patch can be
   processed successfully]({% post_url
   2023-01-11-postgresql-largest-commits %}), but that's not a hard
   rule, just indirect advice.  Keep your patch free of unrelated
   cleanup.  If you have cleanup, see below.

   _[Example:
   [Here](https://www.postgresql.org/message-id/a855795d-e697-4fa5-8698-d20122126567%40eisentraut.org)
   is the first patch submission for a potential new feature.  It's
   just a big patch for now, early in development, maybe we'll find
   ways to organize it differently later.  But for now, keep it
   simple.]_

1. If you work on a larger project, you will inevitably find stuff you
   want to clean up, weird formatting, confusing comments, ancient
   coding style, etc.  This does not belong in your main patch, people
   will get upset about that.  You could either split your patch now,
   or you just send a new patch in a separate email thread.  The
   latter is probably easiest: If you write an email, "here is some
   cleanup I did while working on something else", together with a
   really clean and obvious patch, someone can quickly pick that up
   and review it or commit it.  (Note, if you have several different
   kinds of cleanups, such as formatting changes, comment typos, etc.,
   it's probably also good to split those into separate patches
   attached to the same email.)  If instead you submit those cleanups
   with the main patch, then chances are fewer people will see it,
   because the big patch at the end will scare them away.

   _[Example:
   [Here](https://www.postgresql.org/message-id/flat/89157929-c2b6-817b-6025-8e4b2d89d88f@enterprisedb.com)
   is a thread developing a new feature that has gone on for quite
   some time.  I know a lot of side-cleanups have been done during the
   development, but I kept all of those out of the main patch and the
   main discussion thread.]_

1. Sometimes, if you work on a big project, you will want to do some
   preparatory work first, like refactor some code, add a new API, put
   some testing infrastructure in place, or add test coverage.  This
   would be bad to put into the main patch, because it will make the
   visual inspection of the patch more confusing and difficult.  It
   usually also doesn't make sense to submit these preparatory patches
   in a separate thread, because then you'll lose the context, and
   often you will want to change those preparatory patches as your
   main patch evolves.  So here you should really split your patch
   into a single series.

   Sometimes, the review discussion might reveal that the splitting
   went too far.  Maybe the new API does not make sense without the
   main feature, and the reviewers think they should be committed
   together.  Or maybe, as a compromise, they can be committed
   separately, but only in one batch, once the whole series has been
   agreed upon.  That's ok, that's part of patch review.  Reviewing is
   not only about patch contents but also a bit about patch structure.
   Sometimes it's also useful to make smaller splits during early
   development, and then combine the patches after they have been
   reviewed.  Also, sometimes, the preparation work becomes so
   significant that it becomes a feature of its own, in which case,
   see the next case.

   _[Example:
   [Here](https://www.postgresql.org/message-id/a368248e-69e4-40be-9c07-6c3b5880b0a6@eisentraut.org)
   is the first patch submission for a possible new feature.  Note how
   the first two patches in the series reorganize the tests before
   anything else.  This would have been really confusing if it had
   been included in the main patch.  The third and fourth patches are
   arguably cleanups that could be submitted separately, but I felt
   they make more sense if kept in this context.  Note also how my
   email message explains the patch structure and guides any
   reviewers.]_

1. You are working on a big project, but it's really a collection or
   sequence of smaller projects.  (Or alternatively, you are working
   on a _huge_ project, but it's really a collection or sequence of
   _big_ projects.)  If you can figure out how to divide this up, then
   that's great.  You made your patches smaller but each patch is
   useful on its own.

   Here again, the granularity can vary as the feature development
   progresses or after reviews.  Maybe your first patch adds support
   for some feature to the UPDATE command, and the second patch to the
   DELETE command, and the third one to the MERGE command.  This kind
   of thing can be useful during code review, as each increment can be
   considered and tested separately, but maybe for final commit you
   want to combine them; it depends.

   But if the smaller projects can be fully separated without losing
   context, they should probably just be separate threads, especially
   if they are each fairly big on their own.

   _[Example:
   [Here](https://www.postgresql.org/message-id/CA%2BrenyVyMOb%2Bt6QNoq%3DPBK1CY_oa9wdJrObjj6S1-RK9CxYwKQ%40mail.gmail.com)
   is a patch submission in the middle of a larger thread.  This
   submission organized the previous work into this
   incremental-features fashion, after some offline discussions.  This
   ultimately allowed this very large feature set to make progress.]_

What is not useful in my opinion is splitting patches in a way that
each patch is not considered a self-contained patch.  For example,
splitting documentation or tests into separate patches is
counter-useful.  I wouldn't commit it like that, and it doesn't help
during review, because I can find the documentation, code, and test
parts of a patch just fine, but not if they are in different patches.
Another example is where one patch adds a GUC and a second patch makes
use of it.  You could argue that this is akin to first adding an API
and then using it, but I think in this case it goes too far.
Realistically, the first patch cannot be considered on its own if we
don't know how the new GUC is going to be used.

When you submit a patch series, explain under what premise you have
split the patches, and explain the state and review expectations for
each patch of the series.  For example, if you send cleanups plus main
patch, you might want to write, "the first three patches are just
trivial cleanups, if people want to look at those first, we could get
them out of the way".  Otherwise, they will linger there forever until
the main patch becomes ready.  (Hence the suggestion above to send
cleanups separately.)  If you send a patch series consisting of
several independent subfeatures, then you might want to guide the
focus of reviewers.  Otherwise, they might all end up reviewing the
middle patch, which might make the least sense to commit first.  Or
maybe the last patch in the series is still in development and you'd
rather have reviewers to finalize the reviews of the first couple of
patches.  Say that, or otherwise they'll spend all their time
reporting the faults in your last patch that you already knew.  Or
maybe you do want all patches to be reviewed equally because you want
to verify some cross-cutting issues.

My general expectation is that patches are to be considered in order.
So if I see a series of like five patches, I'll probably briefly look
over each patch and the whole discussion to get the general idea, then
I'll run each patch through the test suites incrementally, and then
I'll focus on reviewing the first patch in detail.

A patch series can also be considered a queue of sorts.  Maybe you
submit a series of five patches.  Then, after some rounds of reviews,
the first patch gets committed.  Then you submit the remaining four
patches for the next review rounds.  Maybe after a while you add some
additional functionality, so you add another patch at the end.  Or you
find some issues with what has already been committed, and so you
insert a new patch at the front of the queue (remember, first patch
first).  However, this generally only works well if the patch authors
and reviewers how some sort of understanding about this.  Otherwise,
you'll just have a patch series that is always changing and never
ends, and everyone will get tired of it.  Think about the scope of
your project, and if appropriate start a separate thread for a new
topic.

Summary:
* Each patch in a series is self-contained.
* If in doubt, start with a single patch.
* Communicate structure and expectations to reviewers.
