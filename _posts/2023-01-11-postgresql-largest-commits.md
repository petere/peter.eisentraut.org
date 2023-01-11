---
title: "PostgreSQL largest commits"
comments: true
tags:
- postgresql
---

I like to poke around the PostgreSQL Git repository to find
[interesting]({% post_url 2022-12-13-postgresql-commit-times %})
[statistics]({% post_url 2022-10-25-postgresql-15-statistics %}) and
trends that affect PostgreSQL development.  The question I had lately
is, what are the largest patches that have been committed?  That might
indicate some kind of upper bound on the size of features you can get
committed in one piece.  If something is larger, you might need to
split it up.

We could just look for the largest commits, something like `git show
... | wc -c`.  But that would show changes like reformatting code,
adding a function argument in a bunch of places, and similar
repetitive changes, also commits that remove or revert large amounts
of code --- commits that are large but not intellectually large.

A better approximation might be: lines added minus lines removed.  If
you're just reformatting, that value will be close to zero.  If
you're adding a new feature, it will be large.

Now how do we find these?  `git log` has a bunch of options to filter
commits, but it doesn't look like it has anything to filter by lines
added or removed.  So I wrote up something manual:

```sh
set -eu

for commit in $(git rev-list "$@"); do
    stat=$(git show --format=format: --shortstat $commit)
    insertions=$(echo -n "$stat" | sed -E -n 's/.* ([0-9]+) insertion.*/\1/p')
    deletions=$(echo -n "$stat" | sed -E -n 's/.* ([0-9]+) deletion.*/\1/p')
    test -n "$insertions" || insertions=0
    test -n "$deletions" || deletions=0
    git show $commit | grep -q 'Translation updates' && continue

    if test $(($insertions - $deletions > 5000)) = 1; then
        git -P show --oneline --shortstat $commit
    fi
done
```

I applied two filters here: I'm excluding translation update commits,
which are mechanical and uninteresting for this discussion.  And I
used a threshold of 5000 net lines added, which is obviously
arbitrary and can be adjusted depending on what you want to get out of
it.

Also, when you run this you will quickly realize that a few other
kinds of commits ought to be excluded as well: 1) commits that update
files from a source elsewhere (e.g., `ppport.h`, snowball), 2) commits
that update large generated files (e.g., `unicode_norm_table.h`), and
3) commits that only (or mostly) add large expected test output (for
example, commit
[`e349c95d3e`](https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=e349c95d3e)
adds 942 new lines of test input, together with 4208 lines of output,
which were presumably not typed in by hand).

With that in mind, here are the largest patches in the last few development cycles:

PostgreSQL 15 (`git rev-list REL_14_STABLE..REL_15_0`):

```
7103ebb7aa Add support for MERGE SQL command
 95 files changed, 8726 insertions(+), 167 deletions(-)
```

PostgreSQL 14 (`git rev-list REL_13_STABLE..REL_14_0`):

```
a4d75c86bf Extended statistics on expressions
 43 files changed, 5982 insertions(+), 963 deletions(-)
ab596105b5 BRIN minmax-multi indexes
 19 files changed, 5286 insertions(+), 26 deletions(-)
6df7a9698b Multirange datatypes
 67 files changed, 10568 insertions(+), 270 deletions(-)
```

PostgreSQL 13 (`git rev-list REL_12_STABLE..REL_13_0`):

```
c8434d64ce Allow partitionwise joins in more cases.
 11 files changed, 5392 insertions(+), 83 deletions(-)
```

PostgreSQL 12 (`git rev-list REL_11_STABLE..REL_12_0`):

```
72b6460336 Partial implementation of SQL/JSON path language
 33 files changed, 9079 insertions(+), 55 deletions(-)
```

PostgreSQL 11 (`git rev-list REL_10_STABLE..REL_11_0`):

```
372728b0d4 Replace our traditional initial-catalog-data format with a better design.
 110 files changed, 22928 insertions(+), 12480 deletions(-)
```

(a [hidden gem]({% post_url 2022-12-27-postgresql-hidden-gems %})!)

(PostgreSQL 11 also included large commits that added MERGE, which
were later reverted, so I didn't include them here.)

PostgreSQL 10 (`git rev-list REL9_6_STABLE..REL_10_0`):

```
665d1fad99 Logical replication
 119 files changed, 13354 insertions(+), 95 deletions(-)
f0e44751d7 Implement table partitioning.
 85 files changed, 8886 insertions(+), 271 deletions(-)
```

And PostgreSQL 16 so far:

```
e6927270cd meson: Add initial version of meson based build system
 265 files changed, 10962 insertions(+)
```

So about 10&thinsp;000 new lines net appears to be the limit?
