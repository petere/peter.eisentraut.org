---
title: "How about trailing commas in SQL?"
comments: true
tags:
- postgresql
- sql
---

Anecdotally, this might be the most requested feature in SQL: Allow
some trailing commas.

The classic example is

```
SELECT a,
       b,
       c,  -- here
FROM ...
```

Another one is

```
CREATE TABLE tab1 (
    a int,
    b int,
    c int,  -- here
)
```

There might be a few other popular ones.  (Please send feedback.)

How could we support that?  And by "we", I primarily mean, either in
PostgreSQL, which I work on, or in the SQL standard, which I work on.
And ultimately in other SQL implementations, which may or may not
follow either of these two sources.

Implementing the above two cases in PostgreSQL is easy.  Done?!?

But there are loads more places in SQL with comma-separated lists, for
example, array constructors, row constructors, function calls, as well
as in various commands, such as function definitions, type
definitions, `COPY`, `CREATE PUBLICATION`, many others.  What to do
about this?  Is there a line to draw somewhere?

I can see a few possible approaches:

1. We just support a few of the most requested cases.  Over time, we
   can add a few more if people request it.

2. We support most cases, except the ones that are too complicated to
   implement or cause grammar conflicts.

3. We rigorously support trailing commas everywhere commas are used
   and maintain this for future additions.

These are all problematic, in my opinion.  If we do option 1, then how
do we determine what is popular?  And if we change it over time, then
there will be a mix of versions that support different things, and it
will be very confusing.  Option 2 is weird, how do you determine the
cutoff?  Option 3 would do the job, but it would obviously be a lot of
work.  And there might be some cases where it's impossible, and it
would have to degrade into option 2.

In any case, it would also be nice to get this into the SQL standard.
Then we can aim for some consistency across implementations in the
long run.

There, we have the same questions, but we need to be even more
rigorous.

1. If we just add support for a few that we feel like are most
   requested and add more over time, then we need to manage different
   conformance rules and a bunch of feature codes.  I think this would
   be confusing for implementers and users.  I still remember that C
   supported trailing commas in structure values in C89 but in enum
   declarations only in C99.  That was confusing!  And now consider
   having that but many more times!

2. There is likely no option 2, because adding `<optional trailing
   comma>` (or whatever it might be called) all over the standard text
   is easy.  There are no cases that are "too complicated".

3. We could add it everywhere.  That'd be straightforward.  But then
   we don't take implementation concerns into account.  Are there
   cases where it's too complicated too parse?  Would it require
   additional reserved words?  How do we verify that this is actually
   implementable?  I think this would result in fragmentation in the
   actual implementations, which is exactly not the point.

I researched about a dozen programming languages.  Most of them
nowadays have some trailing-comma support somewhere.  But that's where
the similarities end.  Usually, you can see trailing commas support in
something like enum definitions or array initialization.  But how
about function calls?  Or function definitions?  You can easily find
three different answers!  Also, programming languages generally have
much fewer syntactic constructs than SQL, which is generally a good
thing, but then it's hard to make a good comparison or find good
guidance.

On the SQL side, DuckDB has [advertised
support](https://duckdb.org/docs/sql/dialect/friendly_sql.html#trailing-commas)
for trailing commas, but I have not found rigorous answers to the
above questions.  Trying it out, they cover some of the popular cases,
but you can easily find places where it doesn't work for no obvious
reason.  Now if other implementations do it their own way as well,
we'll just get chaos.

What do you think?  What's the way forward here?
