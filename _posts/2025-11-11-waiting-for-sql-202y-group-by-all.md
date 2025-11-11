---
title: "Waiting for SQL:202y: GROUP BY ALL"
comments: true
tags:
- postgresql
- sql
- sql:202y
---

Making GROUP BY a bit easier to use is in my experience among the top
three requested features in SQL.

Like, if you do

```
CREATE TABLE t1 (a int, b int, ...);

SELECT a, avg(b) FROM t1 GROUP BY a;
```

the column list in the `GROUP BY` clause doesn't convey much
information.  Of course you wanted to group by `a`, there is no other
reasonable alternative.  You can't not group by `a` because that would
be an error, and you can't group by things besides `a`, because there
is nothing else in the select list other than the aggregate.

The problem gets worse if you have a longer select list or complicated
expressions, because you need to repeat these in the GROUP BY clause
and carefully keep them updated if you change something.  (Or you can
try to work around this by using subqueries.)  Could be easier!

A number of
implementations[^databricks][^duckdb][^bigquery][^snowflake] have
adopted the syntax `GROUP BY ALL` to simplify this.

```
SELECT a, avg(b) FROM t1 GROUP BY ALL;
```

[^databricks]: <https://docs.databricks.com/aws/en/sql/language-manual/sql-ref-syntax-qry-select-groupby>
[^duckdb]:     <https://duckdb.org/docs/stable/sql/query_syntax/groupby>
[^bigquery]:   <https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#group_by_all>
[^snowflake]:  <https://docs.snowflake.com/en/sql-reference/constructs/group-by#label-group-by-all-columns>

The SQL standard working group discussed this feature informally at
the June 2025 meeting, and there was consensus about going forward
with it.

At the September 2025 meeting, a formal change proposal was brought
forward and accepted.  (So, technically, it's just a working draft
right now, and it won't be final until the standard is released.)

The formal meaning of `GROUP BY ALL` is that it expands to a list of
the elements of the select list that do not contain aggregate
functions.  So in

```
SELECT a, avg(b) FROM t1 GROUP BY ALL;
```

`a` does not contain an aggregate function, but `avg(b)` does, so
`GROUP BY ALL` resolves to `GROUP BY a`, as expected.

This doesn't completely remove the need for explicit `GROUP BY` lists.
Consider a more complicated case like

```
CREATE TABLE t1 (a int, b int, c int, d int, ...);

SELECT a, avg(b) + c + d FROM t1 GROUP BY ALL;
```

Here, `a` does not contain an aggregate function, but `avg(b) + c + d`
does contain an aggregate function, so the query resolves to

```
SELECT a, avg(b) + c + d FROM t1 GROUP BY a;
```

But that is not valid, because you need to account for the ungrouped
columns `c` and `d` somehow.  It's not clear what `GROUP BY ALL`
should do with this.  You could have meant `GROUP BY a, c + d` or
maybe `GROUP BY a, c, d` or maybe even `GROUP BY a + c + d`.  `GROUP
BY ALL`, as currently specified, intentionally does not handle that
and leaves it up to the query author to write explicitly what they
want.

Here is another example:

```
INSERT INTO t1 VALUES (1, 2, 100), (2, 1, 200), (2, 2, 300);

SELECT a + b, avg(c) FROM t1 GROUP BY ALL;
```

This means

```
SELECT a + b, avg(c) FROM t1 GROUP BY a + b;
```

_not_

```
SELECT a + b, avg(c) FROM t1 GROUP BY a, b;
```

which returns a different result.

I have found that the documentations of some of the products with
existing implementations are quite handwavy and superficial about
details like this, but the standardization needs to be precise.

The SQL standard doesn't actually support expressions in the `GROUP
BY` list, only column references, so this last query is technically
not conforming.  But there is an intent to fix this soon.  But then
you also need to consider more special cases like invocation of
user-defined functions or subqueries, so some detail work will be
required.

All that said, this kind of shortcut syntax does have risks.  Similar
to other shortcuts like `SELECT *`, this might cause queries to change
unintentionally if changes are made elsewhere in the command.  For
example, if you have

```
SELECT a, avg(b) FROM t1 GROUP BY ALL;
```

and then change it to

```
SELECT a, c, avg(b) FROM t1 GROUP BY ALL;
```

this will cause the `GROUP BY` clause to change implicitly.  Maybe
this is not what you meant.  This example query is very small, but
often times these aggregation queries are long and nested, and someone
editing it might not be fully aware that grouping applies to the
query.

So it would probably be good to use this syntax with a bit of caution,
and maybe use it mainly for interactively written queries and
structurally simple queries.

In the meantime, Oracle Database has also implemented and
released[^oracle][^gerald] `GROUP BY ALL` support.  (And they did all
the work writing the SQL standard change proposal.)

[^oracle]: <https://docs.oracle.com/en/database/oracle/oracle-database/26/nfcoa/ru23_9.html>
[^gerald]: <https://www.geraldonit.com/whats-new-for-developers-in-oracle-database-23-9/>

PostgreSQL implemented[^pgmail][^pgdoc] it while I was waiting at the
airport to fly home from the working group meeting.  There had already
been a patch pending, but the hackers group was hesitant to move
forward without standardization.  So once that was done, the patch was
quickly accepted.  This will be released next year.

[^pgmail]: <https://www.postgresql.org/message-id/634aca95-6db5-4beb-b18d-67e65582817f%40eisentraut.org>
[^pgdoc]:  <https://www.postgresql.org/docs/devel/sql-select.html#SQL-GROUPBY>

---
