---
layout: post
title: "PostgreSQL system catalogs schema diagrams"
comments: true
tags:
- graphviz
- postgresql
---

Some time ago, someone asked on a PostgreSQL mailing list whether
there was a diagram of the PostgreSQL system catalogs.  There wasn't
at the time.  Something like that used to be included in the
PostgreSQL documentation, but it was never updated, and so it was
eventually removed.

I was fond of a tool called
[`postgresql_autodoc`](https://github.com/cbbrowne/autodoc) that could
create schema diagrams automatically by querying catalog information.
I was thinking why we couldn't use that on the system catalogs, too.

The problem was that the system catalogs didn't have real constraints
defined, and so a tool like `postgresql_autodoc` wouldn't be able to
figure out the associations between tables.  But could we not fix
that?

First, I set out to [add primary
keys](https://www.postgresql.org/message-id/flat/dc5f44d9-5ec1-a596-0251-dadadcdede98%402ndquadrant.com)
and unique constraints to system catalogs.  Before that, they only had
unique indexes, which do the same thing in effect, but they are not a
declaration of intent.  So now, almost all system catalogs have a
genuine primary key constraint defined.  This should also help GUI
tools that want to browse and update tables but get upset if there is
no primary key defined.

I had originally wanted to later add foreign key constraints as well,
but that turned out to be a bit more complicated.  So others [devised
a
workaround](https://www.postgresql.org/message-id/flat/3240355.1612129197%40sss.pgh.pa.us):
We don't declare full constraints, but there is a system function
(`pg_get_catalog_foreign_keys`) that you can get the foreign key
relationships from.

With all that necessary metadata available, you can now query it.  I
just wrote my own [small program](https://github.com/petere/pgcatviz)
to produce a [Graphviz](https://graphviz.org/) source file.  You can
see the results here: <https://petere.github.io/pgcatviz/>.  As you
can see, the results are pretty big and unwieldy.  Maybe someone wants
to play with the Graphviz formatting options a bit.  (Feel free to
send pull requests.)  But in any case, all the information is there
now.
