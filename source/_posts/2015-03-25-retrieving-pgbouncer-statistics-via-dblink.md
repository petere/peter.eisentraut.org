---
layout: post
title: "Retrieving PgBouncer statistics via dblink"
date: 2015-03-25 20:00:00 -0400
comments: true
categories:
- dblink
- pgbouncer
- postgresql
- planet postgresql
---

[PgBouncer](https://wiki.postgresql.org/wiki/PgBouncer) has a virtual
database called `pgbouncer`.  If you connect to that you can run
special SQL-like commands, for example

    $ psql -p 6432 pgbouncer
    =# SHOW pools;
    ┌─[ RECORD 1 ]───────────┐
    │ database   │ pgbouncer │
    │ user       │ pgbouncer │
    │ cl_active  │ 1         │
    │ cl_waiting │ 0         │
    │ sv_active  │ 0         │
    │ sv_idle    │ 0         │
    │ sv_used    │ 0         │
    │ sv_tested  │ 0         │
    │ sv_login   │ 0         │
    │ maxwait    │ 0         │
    └────────────┴───────────┘

This is quite nice, but unfortunately, you cannot run full SQL queries
against that data.  So you couldn't do something like

```sql
SELECT * FROM pgbouncer.pools WHERE maxwait > 0;
```

Well, here is a way: From a regular PostgreSQL database, connect to
PgBouncer using dblink.  For each `SHOW` command provided by
PgBouncer, create a view.  Then that SQL query actually works.

But before you start doing that, I have already done that here:

{% gist petere/b4e2aa7cb4a073e07630 pgbouncer-schema.sql %}

Here is another useful example.  If you're tracing back connections
from the database server through PgBouncer to the client, try this:

```sql
SELECT * FROM pgbouncer.servers LEFT JOIN pgbouncer.clients ON servers.link = clients.ptr;
```

Unfortunately, different versions of PgBouncer return a different
number of columns for some commands.  Then you will need different
view definitions.  I haven't determined a way to handle that
elegantly.
