---
layout: post
title: "Have problems with PostgreSQL?  Try using Hive!"
date: 2015-08-14 20:00:00 -0400
comments: true
categories:
- postgresql
- hadoop
- hive
- planet postgresql
---

So I had this PostgreSQL database that was getting a bit too big, and
since it was really only for analytics, I figured it would be a good
fit for putting in Hadoop+Hive instead.

(For those not completely familiar with this: Hadoop is sort of a job
tracker and distributed file system. Hive is an SQL-like layer on top
of that.  I know the cool kids are now using Spark.  Maybe for another
day.)

The first thing you need to learn about the Hadoop ecosystem is its
idiosyncratically fragmented structure.  With PostgreSQL, you
basically have the community website, the community mailing lists, the
community source code distribution, the community binaries, and a
handful of binaries made by Linux distributions.  If you search the
web for a problem with PostgreSQL, you will normally gets hits on one
or more of: the documentation, the mailing lists, third-party mirrors
of the mailing lists, or Stack Overflow.  With Hadoop, you have the
resources provided by the Apache Software Foundation, including the
source distribution, bug tracker, documentation, and then bunch of
commercial vendors with their parallel universes, including their own
mutually incompatible binary distributions, their own copy of the
documentation, their own mailing lists, their own bug trackers, etc.
When you search for a problem with Hadoop, you will typically get hits
from three separate copies of the documentation, about eight mailing
lists, fifteen tutorials, and one thousand blog posts.  And about 20
unanswered posts on Stack Overflow.  Different vendors also favor
different technology extensions.  So if, say, you read that you should
use some storage method, chances are it's not even supported in a
given distribution.

The next thing to know is that any information about Hadoop that is
older than about two years is obsolete.  Because they keep changing
everything from command names to basic architecture.  Don't even
bother reading old stuff.  Don't even bother reading anything.

So Hive.  The basic setup is actually fairly well documented.  You set
up a Hadoop cluster, HDFS, create a few directories.  Getting the
permissions sorted out during these initial steps is not easy, but it
seldom is.  So you can create a few tables, load some data, run a few
queries.

Nevermind that in its default configuration `hive` spits out about a
dozen warnings on every startup about deprecated parameters and jar
file conflicts.  This is apparently well known.  Look around in the
internet for hive examples.  They show the same output.  Apparently
the packaged versions of Hadoop and Hive are not tuned for each other.

Then you learn: In the default configuration, there can only be *one*
Hive session connected at once.  It doesn't tell you this.  Instead,
when the second session wants to connect, it tells you

    Exception in thread "main" java.lang.RuntimeException: java.lang.RuntimeException: Unable to instantiate org.apache.hadoop.hive.metastore.HiveMetaStoreClient

followed by hundreds of lines of exception traces.  This is Hive-speak
for: "there is already one session connected".

You see, Hive needs a, cough, cough, relational database to store its
schema.  By default, it uses embedded Derby, which allows only one
connection at a time.  If you want to connect more than one session at
once, you need to set up an external "Hive metastore" on a MySQL or
PostgreSQL database.

Nevermind that Derby can actually run in server mode.  That's
apparently not supported by Hive.

So I had a PostgreSQL database handy and tried to set that up.  I
installed the PostgreSQL JDBC driver, created an external database,
changed the Hive configuration to use an external database.

At this point, it turned out that the PostgreSQL JDBC driver was
broken, so I had to downgrade to an older version.  (The driver has
since been fixed.)

After I got one that was working, Hive kept complaining that it
couldn't find a driver that matches the JDBC URL
`jdbc:postgresql://somehost/hive_metastore`.  The PostgreSQL JDBC
driver explains in detail how to load the driver, but how do I get
that into Hive?

The first suggestion from the internet was to add something like this
to `.hiverc`:

    add jar /usr/share/java/postgresql-jdbc.jar;

That doesn't work.  Remember, don't believe anything you read on the
internet.

In between I even tried download the MySQL JDBC driver (no, I don't
want to sign in with my Oracle account), but it had the same problem.

`hive` is actually a shell script which loads another shell script
which loads a bunch of other shell scripts, which eventually starts
`java`.  After randomly poking around I determined that if I did

    export HIVE_AUX_JARS_PATH=/usr/share/java/

it would pick up the jar files in that directory.  OK, that worked.

Now I can create tables, load data, run simple queries, from more than
one session.  So I could do

    SELECT * FROM mytable;

But as soon as I ran

    SELECT count(*) FROM mytable;

it crapped out again:

    java.io.FileNotFoundException: File does not exist: hdfs://namenode/usr/share/java/jline-0.9.94.jar

So it's apparently looking for some jar file on HDFS rather than the
regular file system.  Some totally unrelated jar file, too.

The difference between the two queries is that the first one is
answered by just dumping out data locally, whereas the second one
generates a distributed map-reduce job.  It doesn't tell you that
beforehand, of course.  Or even afterwards.

After a while I figured that this must have something to do with the
`HIVE_AUX_JARS_PATH` setting.  I changed that to

    export HIVE_AUX_JARS_PATH=/usr/share/java/postgresql-jdbc.jar;

so it would look at only one file, and sure enough it now complains

    java.io.FileNotFoundException: File does not exist: hdfs://namenode/usr/share/java/postgresql-jdbc.jar

Apparently, the `HIVE_AUX_JARS_PATH` facility is for adding jars that
contain user-defined functions that you need at run time.  As far as I
can tell, there is no separate setting for adding jars that you only
need locally.

There are workarounds for that on the internet, of varying
bizarreness, none of which worked.  Remember, don't believe anything
you read on the internet.

In the end, I indulged it and just uploaded that jar file into HDFS.
Whatever.

I then put my data loading job into cron, which quickly crapped out
because `JAVA_HOME` is not set in the cron environment.  After that
was fixed, I let my data loading jobs run for a while.

Later, I wanted clear out the previous experiments, drop all tables,
and start again.  Apparently, dropping a table in Hive takes a very
long time.  Actually, no.  When you use PostgreSQL for the Hive
metastore, any attempt to drop a table will *hang indefinitely*.

[Someone](https://www.mail-archive.com/user@hive.apache.org/msg00515.html)
summarized the issue:

> You are the first person I have heard of using postgres. I commend
> you for not succumbing to the social pressure and just installing
> mysql.  However I would advice succumbing to the social pressure and
> using either derby or mysql.
>
> The reason I say this is because jpox
> "has support" for a number of data stores (M$ SQL server) however,
> people have run into issues with them. Databases other then derby
> and mysql 'should work' but are generally untested.

Not that actually testing it would take much work.  It's not like Hive
doesn't have any tests.  Just add some tests.

It's funny that they didn't write "You are the first person I have
heard of using hive".  Clearly, nobody has ever actually used this.

Anyway, somehow I ended up creating the metastore schema manually by
copying and pasting various pieces from the internet and raw files.
Shudder.

How about more fun?  Here is a run-of-the-mill SQL parse error:

```
NoViableAltException(26@[221:1: constant : ( Number | dateLiteral | StringLiteral | stringLiteralSequence | BigintLiteral | SmallintLiteral | TinyintLiteral | DecimalLiteral | charSetStringLiteral | booleanValue );])
	at org.antlr.runtime.DFA.noViableAlt(DFA.java:158)
	at org.antlr.runtime.DFA.predict(DFA.java:116)
	at org.apache.hadoop.hive.ql.parse.HiveParser_IdentifiersParser.constant(HiveParser_IdentifiersParser.java:4377)
	at org.apache.hadoop.hive.ql.parse.HiveParser_IdentifiersParser.partitionVal(HiveParser_IdentifiersParser.java:8444)
	at org.apache.hadoop.hive.ql.parse.HiveParser_IdentifiersParser.partitionSpec(HiveParser_IdentifiersParser.java:8283)
	at org.apache.hadoop.hive.ql.parse.HiveParser_IdentifiersParser.tableOrPartition(HiveParser_IdentifiersParser.java:8161)
	at org.apache.hadoop.hive.ql.parse.HiveParser.tableOrPartition(HiveParser.java:31397)
	at org.apache.hadoop.hive.ql.parse.HiveParser.insertClause(HiveParser.java:30914)
	at org.apache.hadoop.hive.ql.parse.HiveParser.regular_body(HiveParser.java:29076)
	at org.apache.hadoop.hive.ql.parse.HiveParser.queryStatement(HiveParser.java:28968)
	at org.apache.hadoop.hive.ql.parse.HiveParser.queryStatementExpression(HiveParser.java:28762)
	at org.apache.hadoop.hive.ql.parse.HiveParser.execStatement(HiveParser.java:1238)
	at org.apache.hadoop.hive.ql.parse.HiveParser.statement(HiveParser.java:938)
	at org.apache.hadoop.hive.ql.parse.ParseDriver.parse(ParseDriver.java:190)
	at org.apache.hadoop.hive.ql.Driver.compile(Driver.java:424)
	at org.apache.hadoop.hive.ql.Driver.compile(Driver.java:342)
	at org.apache.hadoop.hive.ql.Driver.runInternal(Driver.java:1000)
	at org.apache.hadoop.hive.ql.Driver.run(Driver.java:911)
	at org.apache.hadoop.hive.cli.CliDriver.processLocalCmd(CliDriver.java:259)
	at org.apache.hadoop.hive.cli.CliDriver.processCmd(CliDriver.java:216)
	at org.apache.hadoop.hive.cli.CliDriver.processLine(CliDriver.java:413)
	at org.apache.hadoop.hive.cli.CliDriver.processLine(CliDriver.java:348)
	at org.apache.hadoop.hive.cli.CliDriver.processReader(CliDriver.java:446)
	at org.apache.hadoop.hive.cli.CliDriver.processFile(CliDriver.java:456)
	at org.apache.hadoop.hive.cli.CliDriver.executeDriver(CliDriver.java:737)
	at org.apache.hadoop.hive.cli.CliDriver.run(CliDriver.java:675)
	at org.apache.hadoop.hive.cli.CliDriver.main(CliDriver.java:614)
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:57)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:622)
	at org.apache.hadoop.util.RunJar.main(RunJar.java:212)
FAILED: ParseException line 4:20 cannot recognize input near 'year' '(' 'event_timestamp' in constant
```

In PostgreSQL, this might say

```
syntax error at or near "("
```

with a pointer to the actual query.

I just put a function call somewhere where it didn't belong.  The
documentation is very terse and confusing about a lot of these things.
And the documentation is kept as a series of wiki pages.

So now I have a really slow distributed version of my PostgreSQL
database, which stores its schema in another PostgreSQL database.
I forgot why I needed that.
