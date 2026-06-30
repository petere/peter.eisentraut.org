---
title: "Waiting for SQL:202y: Stockholm (BMA) meeting report"
comments: true
tags:
- postgresql
- sql
- sql:202y
---

The most recent meeting of ISO/IEC JTC1 SC32 WG3 "Database Languages"
took place from the 15th to the 19th of June 2026 in Stockholm.
"WG3", as we call it, works on standardizing the database languages
SQL and GQL.  In that meeting, a number of proposals that are of
interest to SQL and PostgreSQL were accepted, which I want to report
about here.

The meeting code of this meeting was "BMA", which is the code for a
small airport in Stockholm.  All in-person WG3 meetings are named
after a nearby airport.  In this case, the code "ARN" for Stockholm's
main airport had already been used for a meeting in 2003.  (It is
whimsically intentional that this system prevents the group from
meeting in the same place too many times.)

Now let's look at the new SQL features that were discussed.  (Regards
to all the GQL practitioners, but I'm not qualified enough to report
on that.)

(Note that when I write below that something has been accepted into
the standard, that means it's now in a working draft.  There is still
a bit of a road until all of this is an approved actual standard.)

## QUALIFY

The `QUALIFY` clause has been accepted into the standard.  This clause
is a filter like `WHERE` or `HAVING` but is applied after window
functions.  For example[^codeex]:

[^codeex]: The examples in this article have been adopted from the respective change proposal papers.

<pre><code>SELECT product_name, category, price
FROM products
<b>QUALIFY</b> price > avg(price) OVER (PARTITION BY category);</code></pre>

Previously, you would have to do this filtering by wrapping the query
in a subquery, like

```
SELECT product_name, category, price
FROM (
    SELECT product_name, category, price,
           avg(price) OVER (PARTITION BY category)
               AS category_avg
    FROM products
) AS q
WHERE q.price > q.category_avg
```

The `QUALIFY` clause is already a nonstandard extension in many SQL
implementations.  A patch for PostgreSQL was [in
progress](https://www.postgresql.org/message-id/flat/CAFY6G8euMWRjTEdRV9M%3DRL2_EJNDm5UNeHat9U1FGGwzfjGSfw%40mail.gmail.com)
for PostgreSQL 19, but it was paused because some definitional issues
had to be resolved, which has now been done with the change proposal
to the standard.  So I think we can look forward to seeing progress on
that for PostgreSQL 20.

## INSERT BY NAME

The `INSERT` option `BY NAME` has been accepted into the standard.
This is a nice little usability improvement when you use `INSERT` with
a `SELECT` as the source.  Up until now, you needed to match up the
columns in the `INSERT` and the columns in the `SELECT` output by
position, which is tedious.  Often, it would be more intuitive to have
them matched by name:

<pre><code>INSERT INTO t1 (c1, c2)
    <b>BY NAME</b>
    SELECT c1 * 10 AS c2, c2 + 5 AS c1 FROM t2 WHERE c1 < 5;</code></pre>

The `BY NAME` clause selects this new behavior.  The matching by
position remains the default, and you can now also write `BY POSITION`
to call for it explicitly.

I don't know of anyone working on this for PostgreSQL, but it could be
a relatively simple project for someone to pick up.

## SELECT list EXCLUDE

This is a change proposal paper that I presented.  This allows
excluding columns of the `SELECT *` expansion, and a few more things.
This has now been accepted into the standard.

This was one of the top-three feature requests that I have been
receiving over the years for the SQL standard.[^topthree]

[^topthree]: The other two being [trailing commas]({% post_url 2025-02-11-how-about-trailing-commas-in-sql %}) and [`GROUP BY ALL`]({% post_url 2025-11-11-waiting-for-sql-202y-group-by-all %}).

I first presented this change proposal at the Barcelona meeting in
September 2025.  In the ensuing discussion, some working group
participants raised additional proposals for more star-expansion
postprocessing features, so we postponed the adoption of my proposal
at the time.  I have since worked on consolidating the various
additional ideas, which this is the result of.

So with the adoption of this paper, the following syntax has now been
standardized:

<pre><code>SELECT * <b>(EXCLUDE (a, b)
          REPLACE (c WITH x+y, d WITH z*2)
          RENAME (e AS ee, f AS foo))</b>
FROM t ...</code></pre>

The qualified-asterisk variant

<pre><code>SELECT t.* <b>(EXCLUDE ...)</b> FROM t ...</code></pre>

is also supported.

Syntax similar to this already exists in a number of implementations,
but I found there were a lot of inconsistencies and poorly defined or
poorly documented behaviors.  With this standardization, some of this
could be improved.

A [partial
implementation](https://www.postgresql.org/message-id/flat/CAMWA6yb9GGiJbe9iU88yjurVQCsFgZvW7xSxa0aFLC0Wtz4Aqg%40mail.gmail.com)
for PostgreSQL was begun late in the PostgreSQL 19 cycle.  I look
forward to this being continued and hopefully concluded for PostgreSQL
20.

## JOIN TO ONE

The `JOIN TO ONE` syntax has been accepted into the standard.  This
addition to the join syntax is meant to prevent some mistakes when
writing join queries.  It checks _at run time_ that each row on the
left side of the join is matched up against _at most_ one row on the
right side of the join.  Consider this query:

<pre><code>SELECT ro.room_number, ro.room_type, ro.price, re.guest_name
FROM reservations re
    INNER JOIN <b>TO ONE</b> rooms ro ON ro.room_number = re.room_number
WHERE re.id = 16354;</code></pre>

This will raise an exception if a `reservations` record is matched
against more than one `rooms` record by the join.  (Maybe the reason
was, in this example, that the joins in the query were incomplete.
Maybe you were supposed to also join against a `hotels` table; see
example below.)

There was some debate about how helpful this feature is, especially in
contrast to the topic in the next section below, but in the end there
was consensus for adopting it into the standard.  Maybe a topic for a
separate article.

## Work in progress: Key joins

The key joins proposal was presented and received a significant amount
of interest but was not yet accepted.  (It is a fairly large and
complex proposal and will need further scrutiny and refinement.)

This is a different proposal to prevent mistakes in join queries.  It
proposes a new syntax that enforces at syntax checking time that the
join condition corresponds to a foreign key constraint.

The above example query would be written as a key join like this
(again, not accepted yet, could change):

<pre><code>SELECT ro.room_number, ro.room_type, ro.price, re.guest_name
FROM reservations AS re
JOIN rooms AS ro <b>FOR KEY (room_number) <- re (room_number)</b>
WHERE re.reservation_id = 16354;</code></pre>

This would check that a foreign key exists that matches the join
condition, so something like

```
-- TABLE reservations
FOREIGN KEY (room_number) REFERENCES rooms (room_number)
```

To continue the example, maybe that foreign key doesn't actually
exist, and the real foreign key is

```
-- TABLE reservations
FOREIGN KEY (hotel_id, room_number) REFERENCES rooms (hotel_id, room_number)
```

and the correct query might be:

<pre><code>SELECT ro.room_type, ro.rate, re.guest_name
FROM reservations AS re
JOIN rooms AS ro <b>FOR KEY (hotel_id, room_number) <- re (hotel_id, room_number)</b>
WHERE re.reservation_id = 16354;</code></pre>

There is a proof-of-concept [patch
proposal](https://www.postgresql.org/message-id/flat/00c30670-64e1-4c30-a349-784426d333df%40app.fastmail.com)
for PostgreSQL.  The authors also have their own [web
site](https://keyjoin.org/) for this proposal.

(I'm not directly involved in this work, but I have given feedback on
several occasions.)

## What's next

The original plan was to have one more comment resolution meeting in
October 2026 and then wrap things up with an eye toward publishing a
new version of the SQL standard in the middle of 2027.  (This also
would have lined up nicely with the PostgreSQL 20 schedule.)

Because of the interest in the key joins work, another meeting has now
been scheduled for August 2026 to be able to make progress on that
proposal.

Also, some participants from both the SQL and the GQL camps have
suggested that they may want to delay the publication schedule by
perhaps half a year to be able to fit in some more strategically
important work.

So altogether the schedule is a bit uncertain right now but I suppose
we'll get a clearer picture in August.

In the meantime, as I'm writing this, the PostgreSQL 20 development
cycle is about to kick off, and this article contains some project
ideas in various stages, if someone wants to chip in.

---
