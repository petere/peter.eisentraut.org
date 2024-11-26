---
title: "Why PostgreSQL major version upgrades are hard"
excerpt_separator: <!--more-->
comments: true
tags:
- postgresql
---

Upgrades between [PostgreSQL major
versions](https://www.postgresql.org/support/versioning/) are famously
annoying.  You can't just install the server binaries and restart,
because the format of the data directory is incompatible.

Why is that?  Why can't we just keep the data format compatible?

<!--more-->

Perhaps surprisingly, the data format is actually mostly compatible,
but not completely.  There are just a few things missing that are very
hard to solve.

Let's look at the possible [upgrading
procedures](https://www.postgresql.org/docs/17/upgrading.html):

1. pg_upgrade
2. dump and restore using pg_dumpall
3. logical replication to a new instance

2 and 3 are essentially the same idea: Build a new instance and
transport the data between the instances in a higher-level, compatible
format.

[pg_upgrade](https://www.postgresql.org/docs/17/pgupgrade.html) is
more interesting.  What pg_upgrade does is:

1. Take a dump (using pg_dump) of the _schema_ of the old database,
   and restore that to the new database.  (Actually separately for
   each database in the instance, and in combination with pg_dumpall,
   but that's not important here.)

2. Copy the _data files_ directly from the old instance to the new
   instance.

So the data files, which contain the table and index data, are
actually compatible between major versions.  They have been for a long
time, ever since pg_upgrade was introduced.

How that is managed depends on what is in those files.  For example,
btree has a straightforward versioning mechanism:

    #define BTREE_VERSION   4       /* current version number */
    #define BTREE_MIN_VERSION   2   /* minimum supported version */

heap is more complicated, it just has to maintain compatibility with
whatever old versions might have stored.  But in any case, this works.

What's not compatible is the way the schema (the data definitions, the
metadata for tables etc.) is stored.  This is what pg_upgrade has to
deal with.

So then why is the schema storage incompatible between major versions?

The schema data of a PostgreSQL database is stored in so-called
[system catalogs](https://www.postgresql.org/docs/17/catalogs.html),
which are themselves just tables.  For bootstrapping reasons, and also
some efficiency reasons, the structure of these system catalogs is
hardcoded in the server.  For example, when the system wants to know
the name of a column, it loads the `pg_attribute` row, and it knows at
what offset the `attname` field with the column name begins.  This has
to be hardcoded, because, well, you can't query `pg_attribute` to find
out information about `pg_attribute`.

Whenever a new feature is implemented that needs to store some
information in the system catalogs, this hardcoded knowledge becomes
incorrect.  For example, in PostgreSQL 17, subscriptions got a new
[failover
flag](https://www.postgresql.org/docs/17/sql-createsubscription.html#SQL-CREATESUBSCRIPTION-PARAMS-WITH-FAILOVER).
This failover flag needs to be stored somewhere.  It is stored in the
`subfailover` field of the
[`pg_subscription`](https://www.postgresql.org/docs/17/catalog-pg-subscription.html)
catalog.  Because of that, the hardcoded size of the `pg_subscription`
rows changes, and the offset of some fields after the new
`subfailover` field changes.  (For additional complicated reasons, you
can't just add all new fields to the end.)

There would appear to be an obvious solution for this: The server
source code just has to have conditional code for old catalog layouts.
But this code is very widespread, a rough estimate shows more than a
thousand instances.  So making this happen would be a massive effort
and require significant ongoing maintenance.  So I think before this
could happen, some new ideas would be required for how to first
refactor some of that.

The other problem is that this still wouldn't provide a way to upgrade
the system catalogs to the new layout.  If you upgraded to PostgreSQL
17 and wanted to create a failover subscription, you couldn't, because
the catalogs would still be in the old format.  And then you would
still need to upgrade those somehow, and you'd need tooling to manage
all of that.

Now, in a different world, the system catalogs would have been
designed differently, with compatibility and upgradability in mind.
This idea that system catalogs are normal tables is perhaps an
original Berkeley Postgres idea.  And it's really nice, because it
gives you some useful features, especially transactional DDL with
relatively little additional effort.  But it does make the format
harder to upgrade.

So I tend to think that that's the trade-off of these historical
architectural decisions: easy upgrades or easy transactional DDL.

To be clear, this is not the only barrier to effortless upgrades.  But
I think it's the most significant one.  Another one is that the
serialization format of the internal data structures that record for
example stored views or stored default expressions in the system
catalogs is not managed for compatibility across major versions.
Because there has been no need to so far.  But I think I solution
could be found for that.  There are a number of things like that,
things we haven't even thought about very hard, because there hasn't
been a need.  For example, the format of the write-ahead log (WAL) is
incompatible between major versions.  Because pg_upgrade and none of
the other upgrade procedures preserve the WAL, this is not a problem.
I'm just mentioning it here to indicate that there are other, less
explored issues if the ones we know about are addressed.
