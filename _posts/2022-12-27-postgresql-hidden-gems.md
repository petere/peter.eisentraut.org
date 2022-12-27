---
layout: post
title: "PostgreSQL hidden gems"
comments: true
tags:
- postgresql
---

There is a PostgreSQL major release every year, and every release has
about [200](/blog/2022/10/25/postgresql-15-statistics) changes listed
in the release notes.  A handful of those are typically listed at the
top as "major items", which are highlighted for the benefit of the
public.

Sometimes, a feature that was not highlighted as major turns out later
to have a significant impact.  Consider these features that flew under
the radar at the time:

* [PostgreSQL 9.4](https://www.postgresql.org/docs/9.4/release-9-4.html): [replication slots](https://www.postgresql.org/docs/9.4/warm-standby.html#STREAMING-REPLICATION-SLOTS)

	This is the one that always comes to my mind when I think back
	about "hidden gems".  At the time perhaps not fully understood,
	replication slots are now absolutely essential for any replication
	setup.

* [PostgreSQL 9.5](https://www.postgresql.org/docs/9.5/release-9-5.html): [pg_rewind](https://www.postgresql.org/docs/9.5/app-pgrewind.html)

	pg_rewind existed as an external project outside of the PostgreSQL
	source tree before this.  It is also an important component of
	replication setups nowadays.

* [PostgreSQL 9.6](https://www.postgresql.org/docs/9.6/release-9-6.html): [non-exclusive backups](https://www.postgresql.org/docs/9.6/continuous-archiving.html#BACKUP-LOWLEVEL-BASE-BACKUP)

	Some younger readers might wonder, what?  "Exclusive" backups have
	been removed in PostgreSQL 15, so these "non-exclusive" ones are
	now the only ones.  But at the time, not much attention was paid
	to them.

* [PostgreSQL 10](https://www.postgresql.org/docs/10/release-10.html): [CREATE STATISTICS](https://www.postgresql.org/docs/10/sql-createstatistics.html)

	A favorite magic wand of many PostgreSQL DBAs -- You sprinkle some
	extended statistics on a problem and the poor plan goes away.

* [PostgreSQL 11](https://www.postgresql.org/docs/11/release-11.html): [system catalog file format](https://www.postgresql.org/docs/11/bki.html)

	An internal feature that no developer wants to miss.  Does anyone
	remember adding catalog entries before this?  It was punitive.
	This feature also inspired further similar automation later on.

* [PostgreSQL 12](https://www.postgresql.org/docs/12/release-12.html): [ssl_min_protocol_version](https://www.postgresql.org/docs/12/runtime-config-connection.html#GUC-SSL-MIN-PROTOCOL-VERSION)

	We got bombarded with requests for this, both commercially and in
	the community, even before this was released, because users needed
	to disable old TLS versions because of industry and regulatory
	changes.  Before PostgreSQL 12, you needed to apply confusing
	workarounds; with this it got much easier.  The pressure to
	disable old TLS versions has only increased since then, so
	deploying anything older than PostgreSQL 12 is annoying now.

* [PostgreSQL 13](https://www.postgresql.org/docs/13/release-13.html): [logical replication of partitioned tables](https://www.postgresql.org/docs/13/logical-replication-restrictions.html)

	Two popular features introduced separately in PostgreSQL 10
	finally managed to work together!

* [PostgreSQL 14](https://www.postgresql.org/docs/14/release-14.html): [ALTER TABLE ... DETACH PARTITION ... CONCURRENTLY](https://www.postgresql.org/docs/14/sql-altertable.html)

	Another partition feature that you don't want to miss anymore.
	Especially if you use timestamp-based range partitioning and want
	to throw away old partitions regularly, being able to do it
	without a full lock is essential.

No [PostgreSQL 15](https://www.postgresql.org/docs/15/release-15.html)
in this list yet, it's too early to tell.  What hidden gems will we
find in the future?
