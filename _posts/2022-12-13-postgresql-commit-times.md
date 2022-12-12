---
layout: post
title: "PostgreSQL commit times"
comments: true
tags:
- postgresql
---

PostgreSQL development has certainly professionalized over the years,
in the sense that more people do it as a job now rather than (only) as
a hobby.  I was wondering whether that would be visible in the time of
day when people do publicly visible PostgreSQL work.

We can get the time of all commits over time:

	git log --format='%ci'

Cut off the time zone (We want the local time of the committer) and
save it to a file:

	git log --format='%ci' | cut -d ' ' -f 1,2 > commit-times.txt

Import into PostgreSQL:

	create table commit_times (t timestamp);

(Note I'm using the [dreaded `timestamp without time zone`
type](https://wiki.postgresql.org/wiki/Don%27t_Do_This#Don.27t_use_timestamp_.28without_time_zone.29)
here!)

	\copy commit_times from commit-times.txt

Now let's look at the most common hour things were committed each year:

	select extract(year from t) as year,
	       count(*),
	       mode() within group (order by extract(hour from t))
	from commit_times
	group by extract(year from t)
	order by 1;

```
 year | count | mode
------+-------+------
 1996 |   876 |    6
 1997 |  1698 |    3
 1998 |  1744 |    4
 1999 |  1788 |    2
 2000 |  2535 |   18
 2001 |  3061 |   19
 2002 |  2654 |   20
 2003 |  2416 |   22
 2004 |  2548 |   22
 2005 |  2419 |   21
 2006 |  2152 |   22
 2007 |  2188 |   21
 2008 |  1652 |   19
 2009 |  1388 |   20
 2010 |  1801 |   16
 2011 |  2029 |   12
 2012 |  1604 |   22
 2013 |  1369 |   12
 2014 |  1744 |   15
 2015 |  1816 |   13
 2016 |  2073 |   12
 2017 |  2477 |   11
 2018 |  2127 |   11
 2019 |  2130 |   11
 2020 |  2181 |   13
 2021 |  2271 |   11
 2022 |  2358 |   11
```

You can clearly see this changing over the years.  In the first few
years, people were apparently working under the cover of darkness?!?
Then, from about 2000 to 2010, most commit work happened after office
hours.  Since then, most commit work has clearly been during the day
time.

I can also look back at my own commits:

```
 year | count | mode
------+-------+------
 2000 |   331 |   16
 2001 |   396 |   22
 2002 |   166 |   18
 2003 |   238 |   22
 2004 |   169 |   21
 2005 |    67 |    9
 2006 |    88 |   11
 2007 |   133 |   14
 2008 |   140 |   14
 2009 |   249 |   21
 2010 |   134 |   20
 2011 |   252 |   23
 2012 |   266 |   20
 2013 |   198 |   22
 2014 |   140 |   21
 2015 |   123 |   21
 2016 |   214 |   12
 2017 |   561 |   11
 2018 |   330 |   11
 2019 |   301 |    9
 2020 |   261 |    8
 2021 |   249 |    8
 2022 |   302 |    9
```

This makes sense: Around 2005–2008 and since 2016, I have been working
for PostgreSQL services companies, so a lot of the community work has
been happening during the day.  The other times, I was not, so I was
mostly active "at night".  It's also quite visible that after I moved
from the U.S. to Europe in 2018, my activity moved to earlier in the
day.  That's because mornings are the quieter part of the work day now
(fewer meetings, fewer emails), but I also recall that I made a
conscious shift to not commit things late in the day anymore, after
having gotten burned by the build farm a few times.
