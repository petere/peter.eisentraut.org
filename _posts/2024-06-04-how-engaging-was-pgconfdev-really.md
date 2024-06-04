---
title: "How engaging was PGConf.dev really?"
comments: true
tags:
- git
- postgresql
---

[PGConf.dev 2024](https://2024.pgconf.dev/) is over.  What happened
while no one was watching the source code?

Nothing!

Last Friday I posted:

<iframe src="https://mastodon.social/@petereisentraut/112539665457542969/embed" class="mastodon-embed" style="max-width: 100%; border: 0" width="400" allowfullscreen="allowfullscreen"></iframe><script src="https://mastodon.social/embed.js" async="async"></script>

After that, I was up all night (not really) trying to compute this
correctly in SQL.  And then I figured I might as well wait until the
streak is broken, which has happened now.

Here is what I came up with.

First, load a list of all commits into a table.

```sql
create table commits (
    id int generated always as identity,
    hash varchar,
    commitdate timestamp with time zone
);
```

```sh
git log --reverse --format='format:%h%x09%ci' | psql -c 'copy commits (hash, commitdate) from stdin'
```

(This is using the "committer date" from Git, which is not necessarily
exactly equal to the time the commit was made or pushed, or could be
faked altogether.  But let's ignore that here; this is not a forensic
analysis but just a bit of fun.)

Now compute for each commit the duration since its previous commit:

```sql
select c1.hash,
       c2.commitdate,
       c2.commitdate - c1.commitdate as gap_since_prev
from commits c1 join commits c2 on c1.id = c2.id - 1
order by gap_since_prev desc
fetch first 20 rows only;
```

Result:

```
    hash     |       commitdate       |  gap_since_prev
-------------+------------------------+------------------
 28fad34c7bb | 1996-09-10 06:23:46+00 | 12 days 07:21:03
 94cb3fd8757 | 2001-07-29 22:12:23+00 | 7 days 00:11:19
 37168b8da43 | 2000-08-19 23:39:36+00 | 6 days 20:49:01
 8fea1bd5411 | 2024-06-03 17:10:43+00 | 6 days 12:49:30  -- pgconf.dev 2024
 0acf9c9b284 | 1997-06-20 02:20:26+00 | 6 days 12:11:38
 75ebaa748e5 | 1997-07-08 22:06:46+00 | 6 days 07:53:32
 c5dd292007c | 1996-09-16 05:33:20+00 | 5 days 22:41:52
 41b805b9133 | 1997-07-21 22:29:41+00 | 5 days 20:04:25
 577b0584aa9 | 1997-10-09 04:59:37+00 | 5 days 05:48:11
 4b851b1cfc6 | 1997-08-12 20:16:25+00 | 4 days 16:24:52
 cbdda3e2a94 | 2003-07-14 10:16:45+00 | 4 days 16:18:58
 19740e2fff2 | 1998-12-04 15:34:49+00 | 4 days 15:04:44
 a1480ec1d3b | 2015-10-27 16:20:40+00 | 4 days 14:19:29
 053004a80b5 | 1998-12-12 19:57:51+00 | 4 days 13:37:03
 d8b96ade816 | 1999-01-17 00:18:59+00 | 4 days 11:29:07
 fe7337f2dc3 | 2014-06-09 19:17:23+00 | 4 days 02:50:12
 d82e7c84fa0 | 2008-05-25 21:51:00+00 | 4 days 01:59:59
 4bd4ecf498e | 1997-04-01 09:27:11+00 | 3 days 23:43:18
 4fc6e2fdcfc | 2008-12-24 20:41:29+00 | 3 days 22:37:27
 4e7d10c7cd2 | 2006-03-28 21:17:23+00 | 3 days 22:15:06
(20 rows)
```

So this was the longest hiatus in over 20 years and the 4th-longest of
all time.  It might never be this quiet again!

Looking back through the other list entries, the gap in 2015 was right
_before_ [pgconf.eu](https://2015.pgconf.eu/), the gaps in 2014 and in
late 2008 do not appear to line up with any major conference or code
release event, the gap in May 2008 overlaps with
[PGCon](https://www.pgcon.org/2008/) that year.  Most of the other
entries are obviously more ancient history when there was less project
activity in general.

A conclusion?

<iframe src="https://fosstodon.org/@tomasv/112548459224871721/embed" width="400" allowfullscreen="allowfullscreen" sandbox="allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox allow-forms"></iframe>
