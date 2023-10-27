---
title: "SQL identity columns"
comments: true
tags:
- postgresql
- sql
---

Autoincrementing columns, identity columns, serial columns, whatever
you call it, this is clearly a popular feature in SQL databases, but
with a bunch of different syntaxes.  At least historically.

In SQL:2003, a syntax for this was standardized, which has been
adopted slowly across more implementations:

```
CREATE TABLE t1 (
    a int GENERATED ALWAYS AS IDENTITY,
    ...
);
```

with some variations and additional options not shown here.

This has by now been adopted by a number of implementations:

| Implementation       | Syntax                                          | Notes |
|----------------------|-------------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| Apache Derby         | `GENERATED { ALWAYS | BY DEFAULT } AS IDENTITY` | [docs](https://db.apache.org/derby/docs/10.16/ref/rrefsqlj37836.html#rrefsqlj37836)                       |
| Databricks           | `GENERATED { ALWAYS | BY DEFAULT } AS IDENTITY` | [docs](https://docs.databricks.com/en/sql/language-manual/sql-ref-syntax-ddl-create-table-using.html)      |
| Db2                  | `GENERATED { ALWAYS | BY DEFAULT } AS IDENTITY` | [docs](https://www.ibm.com/docs/en/db2/11.5?topic=statements-create-table#sdx-synid_frag-generated-clause) |
| H2                   | `GENERATED { ALWAYS | BY DEFAULT } AS IDENTITY` | [docs](https://www.h2database.com/html/grammar.html#column_definition)                                     |
| Ingres               | `GENERATED { ALWAYS | BY DEFAULT } AS IDENTITY` | [docs](https://docs.actian.com/ingres/11.2/index.html#page/SQLRef/Column_Specification--Define_Column_Characterist.htm#ww124490)        |
| Oracle               | `GENERATED { ALWAYS | BY DEFAULT } AS IDENTITY` | [docs](https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/CREATE-TABLE.html#GUID-F9CE0CC3-13AE-4744-A43C-EAC7A71AAAB6__CJAECCFH); [since Oracle&nbsp;12](https://oracle-base.com/articles/12c/identity-columns-in-oracle-12cr1)
| PostgreSQL           | `GENERATED { ALWAYS | BY DEFAULT } AS IDENTITY` | [docs](https://www.postgresql.org/docs/16/sql-createtable.html#SQL-CREATETABLE-PARMS-GENERATED-IDENTITY); [since PostgreSQL&nbsp;10](https://www.2ndquadrant.com/en/blog/postgresql-10-identity-columns/)

(Some of the implementations that support the SQL standard syntax also
support their own legacy syntax.)

But while the landscape is better than 20 years ago (it's also
bigger), not all implementations are caught up:

| Implementation       | Syntax                                        | Notes |
|----------------------|-----------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| MariaDB              | `AUTO_INCREMENT`              | [docs](https://mariadb.com/kb/en/create-table/#column-definitions)
| Microsoft SQL Server | `IDENTITY`                    | [docs](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-transact-sql?view=sql-server-ver16)
| MySQL                | `AUTO_INCREMENT`              | [docs](https://dev.mysql.com/doc/refman/8.0/en/create-table.html)
| Snowflake            | `IDENTITY` or `AUTOINCREMENT` | [docs](https://docs.snowflake.com/en/sql-reference/sql/create-table)
| SQLite               | `AUTOINCREMENT`               | [docs](https://www.sqlite.org/lang_createtable.html); [not recommended](https://www.sqlite.org/autoinc.html)

Ok, so there are two and a half nonstandard variants here.

Note that the standardization in SQL does not only cover the syntax
but also questions like, what happens if you insert into an
autoincrementing column manually, what happens when you copy a table
containing such a column, how do these columns interact with triggers,
which data types are supported, and so on.  Hopefully, those who have
adopted the standard syntax have also looked into those issues.
Reading through the documentation of the nonstandard ones, there is
quite a bit of variation there.

Finally, paging Markus Winand to add a page about this on
<https://modern-sql.com/>.  There is already a good [page about
generated
columns](https://modern-sql.com/caniuse/generated-always-as), which
are adjacent to this.
