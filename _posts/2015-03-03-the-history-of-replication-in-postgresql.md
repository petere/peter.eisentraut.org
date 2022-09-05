---
layout: post
title: "The history of replication in PostgreSQL"
date: 2015-03-03 20:00:00 -0500
comments: true
tags:
- postgresql
- replication
---

## 2001: PostgreSQL 7.1: write-ahead log

PostgreSQL 7.1 introduced the write-ahead log (WAL).  Before that
release, all open data files had to be fsynced on every commit, which
is very slow.  Slow fsyncing is still a problem today, but now we're
only worried about fsyncing the WAL, and fsyncing the data files
during the checkpoint process.  Back then, we had to fsync
*everything* *all the time*.

In the original design of university POSTGRES, the lack of a log was
intentional, and contrasted with heavily log-based architectures such
as Oracle.  In Oracle, you need the log to roll back changes.  In
PostgreSQL, the nonoverwriting storage system takes care of that.  But
probably nobody thought about implications for fsyncing back then.

Note that the WAL was really just an implementation detail at this
point.  You couldn't read or archive it.

## 2004: Slony

Just for context: Slony-I 1.0 was
[released](http://lists.slony.info/pipermail/slony1-general/2004-July/000106.html)
in July 2004.

## 2005: PostgreSQL 8.0: point-in-time recovery

PostgreSQL 8.0 added the possibility to copy the WAL somewhere else,
and later play it back, either all the way or to a particular point in
time, hence the name point-in-time recovery (PITR) for this feature.
This feature was mainly intended to relieve `pg_dump` as a backup
method.  Until then, the only backup method was a full dump, which
would get impractical as databases grew.  Hence this method to take an
occasional base backup, which is the expensive part, and then add on
parts of the WAL, which is cheaper.

The basic configuration mechanisms that we still use today, for
example the `recovery.conf` file, were introduced as part of this
feature.

But still no replication here.

## 2008: PostgreSQL 8.3: pg_standby

Crafty people eventually figured that if you archived WAL on one
server and at the same time "recovered" endlessly on another, you'd
have a replication setup.  You could probably have set this up with
your own scripts as early as 8.0, but PostgreSQL 8.3 added the
`pg_standby` program into `contrib`, which gave everyone a standard
tool.  So, arguably, 8.3 is the first release that contained a
semblance of a built-in replication solution.

The standby server was in permanent recovery until promotion, so it
couldn't be read from as it was replicating.  This is what we'd now
call a warm standby.

I think a lot of PostgreSQL 8.3 installations refuse to die, because
this is the first version where you could easily have a reasonably
up-to-date reserve server without resorting to complicated and
sometimes problematic tools like Slony or DRBD.

## 2010: PostgreSQL 9.0: hot standby, streaming replication

In PostgreSQL 9.0, two important replication features arrived
completely independently.  First, the possibility to connect to a
standby server in read-only mode, making it a so-called hot standby.
Whereas before, a standby server was really mainly useful only as a
reserve in case the primary server failed, with hot standby you could
use secondary servers to spread out read-only loads. Second, instead
of relying solely on the WAL archive and recovery functionalities to
transport WAL data, a standby server could connect directly to the
primary server via the existing libpq protocol and obtain WAL data
that way, so-called streaming replication.  The primary use in this
release was that the standby could be more up to date, possibly within
seconds, rather than several minutes with the archive-based approach.
For a robust setup, you would still need to set up an archive.  But
streaming replication was also a forward-looking feature that would
eventually make replication setups easier, by reducing the reliance on
the old archiving mechanisms.

PostgreSQL 9.0 was the first release where one could claim that
PostgreSQL "supports replication" without having to make
qualifications or excuses.  Although it is scheduled to go EOL later
this year, I expect this release will continue to live for a long
time.

## 2011: PostgreSQL 9.1: pg_basebackup, synchronous replication

`pg_basebackup` was one of the features facilitated by streaming
replication that made things easier.  Instead of having to use
external tools like `rsync` for base backups, `pg_basebackup` would
use a normal libpq connection to pull down a base backup, thus
avoiding complicated connection and authentication setups for external
tools.  (Some people continue to favor `rsync` because it is faster
for them.)

PostgreSQL 9.1 also added synchronous replication, which ensures that
data is replicated to the designated synchronous standby before a
`COMMIT` reports success.  This feature is frequently misunderstood by
users.  While it ensures that your data is on at least two servers at
all times, it might actually reduce the availability of your system,
because if the standby server goes down, the primary will also go
down, unless you have a third server available to take over the
synchronous standby duty.

Less widely know perhaps is that PostgreSQL 9.1 also added the
`pg_last_xact_replay_timestamp` function for easy monitoring of
standby lag.

In my experience, the availability of `pg_basebackup` and
`pg_last_xact_replay_timestamp` make PostgreSQL 9.1 the first release
were managing replication was reasonably easy.  Go back further, and
you might feel constrained by the available tools.  But in 9.1, it's
not that much different from what is available in the most recent
releases.

## 2012: PostgreSQL 9.2: cascading replication

Not as widely acclaimed, more for the Slony buffs perhaps,
PostgreSQL 9.2 allowed standbys to fetch their streaming replication
data from other standbys.  A particular consequence of that is that
`pg_basebackup` could copy from a standby server, thus taking the load
off the primary server for setting up a new standby or standalone
copy.

## 2013: PostgreSQL 9.3: standby can follow timeline switch

This did not even make it into the release note highlights.  In
PostgreSQL 9.3, when a primary has two standbys, and one of the
standbys is promoted, the other standby can just keep following the
new primary.  In previous releases, the second standby would have to
be rebuilt.  This improvement makes dynamic infrastructure changes
much simpler.  Not only does it eliminate the time, annoyance, and
performance impact of setting up a new standby, more importantly it
avoids the situation that after a promotion, you don't have any up to
update standbys at all for a while.

## 2014: PostgreSQL 9.4: replication slots, logical decoding

Logical decoding got all the press for PostgreSQL 9.4, but I think
replication slots are the major feature, possibly the biggest
replication feature since PostgreSQL 9.0.  Note that while streaming
replication has gotten more sophisticated over the years, you still
needed a WAL archive for complete robustness.  That is because the
primary server didn't actually keep a list of its supposed standby
servers, it just streamed whatever WAL happened to be requested if it
happened to have it.  If the standby server fell behind sufficiently
far, streaming replication would fail, and recovery from the archive
would kick in.  If you didn't have an archive, the standby would then
no longer be able to catch up and would have to be rebuilt.  And this
archiving mechanism has essentially been unchanged since version 8.0,
when it was designed for an entirely different purpose.  So a
replication setup is actually quite messy: You have to configure an
access path from the primary to the standby (for archiving) and an
access path from the standby to the primary (for streaming).  And if
you wanted to do multiple standbys or cascading, maintaining the
archive could get really complicated.  Moreover, I think a lot of
archiving setups have problematic `archive_command` settings.  For
example, does your `archive_command` fsync the file on the receiving
side?  Probably not.

No more: In PostgreSQL 9.4, you can set up so-called replication
slots, which effectively means that you register a standby with the
primary, and the primary keeps around the WAL for each standby until
the standby has fetched it.  With this, you can completely get rid of
the archiving, unless you need it as a backup.

## 2015? PostgreSQL 9.5? pg_rewind?

One of the remaining problems is that promoting a standby leaves the
old primary unable to change course and follow the new primary.  If
you fail over because the old primary died, then that's not an issue.
But if you just want to swap primary and standby, perhaps because the
standby has more powerful hardware, then the old primary, now standby,
needs to be rebuilt completely from scratch.  Transforming an old
primary into a new standby without a completely new base backup is a
rather intricate problem, but a tool that can do it (currently named
`pg_rewind`) is proposed for inclusion into the next PostgreSQL
release.

## Beyond

One of the problems that this evolution of replication has created is
that the configuration is rather idiosyncratic, quite complicated to
get right, and almost impossible to generalize sufficiently for
documentation, tutorials, and so on.  Dropping archiving with 9.4
might address some of these points, but configuring even just
streaming replication is still weird, even weirder if you don't know
how it got here.  You need to change several obscure configuration
parameters, some on the primary, some on the standby, some of which
require a hard restart of the primary server.  And then you need to
create a new configuration file `recovery.conf`, even though you don't
want to recover anything.  Making changes in this area is mostly a
complex political process, because the existing system has served
people well over many years, and coming up with a new system that is
obviously better and addresses all existing use cases is cumbersome.

Another issue is that all of this functionality has been bolted on to
the write-ahead log mechanism, and that constrains all the uses of the
write-ahead log in various ways.  For example, there are optimizations
that skip WAL logging in certain circumstances, but if you want
replication, you can't use them.  Who doesn't want replication?  Also,
the write-ahead log covers an entire database system and is all or
nothing.  You can't replicate only certain tables, for example, or
consolidate logs from two different sources.

How about not bolting all of this on to the WAL?  Have two different
logs for two different purposes.  This was discussed, especially
around the time streaming replication was built.  But then you'd need
two logs that are *almost* the same.  And the WAL is by design a
bottleneck, so creating another log would probably create performance
problems.

Logical decoding breaks many of these restrictions and will likely be
the foundation for the next round of major replication features.
Examples include partial replication and multimaster replication, some
of which are being worked on right now.

What can we expect from plain WAL logging in the meantime?  Easier
configuration is certainly a common request.  But can we expect major
leaps on functionality?  Who knows.  At one point, something like hot
standby was thought to be nearly impossible.  So there might be
surprises still.
