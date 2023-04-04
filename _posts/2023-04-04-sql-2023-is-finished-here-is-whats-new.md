---
layout: post
title: "SQL:2023 is finished: Here is what's new"
comments: true
tags:
- postgresql
- sql
---

SQL:2023 has been wrapped.  The final text has been submitted by the
working group to ISO Central Secretariat, and it's now up to the ISO
gods when it will be published.  Based on past experience, it could be
between a few weeks and a few months.

In the meantime, we can look at what is new.  The changes can be
grouped into three areas:

1. Various smaller changes to the existing SQL language
2. New features related to JSON
3. A new part for property graph queries

Let's look at each one.

All new functionality in the SQL standard is in the form of optional
features, so I'm giving the feature codes and names below for
reference.  (But this is not an exhaustive list of all new features
codes.  I'm omitting some that are mainly technical changes or for
compatibility.)

## Various changes

### UNIQUE null treatment (F292)

This feature deals with how null values are handled in unique
constraints.  Consider the following:

```sql
CREATE TABLE t1 (
    a int,
    b int,
    c int,
    UNIQUE (a, b, c)
);
```

and

```sql
INSERT INTO t1 VALUES (1, NULL, NULL);
INSERT INTO t1 VALUES (1, NULL, NULL);  -- ?
```

The question is whether the second inserted row should cause a unique
constraint violation.

Apparrently, the old text of the standard was ambiguous about this.
One section seemed to indicate one thing, another section another
thing.  Different implementations have done different things.

To consolidate this, there is now an option to explicitly select a
behavior:

```sql
CREATE TABLE t2 (
    a int,
    b int,
    c int,
    UNIQUE NULLS DISTINCT (a, b, c)
);
```

and

```sql
INSERT INTO t2 VALUES (1, NULL, NULL);
INSERT INTO t2 VALUES (1, NULL, NULL);  -- ok
```

versus

```sql
CREATE TABLE t3 (
    a int,
    b int,
    c int,
    UNIQUE NULLS NOT DISTINCT (a, b, c)
);
```

and

```sql
INSERT INTO t3 VALUES (1, NULL, NULL);
INSERT INTO t3 VALUES (1, NULL, NULL);  -- error
```

The use of words here means: If nulls are considered distinct, then
having more than one of them won't cause a unique constraint
violation.  If nulls are considered not distinct, then having more
than one violates uniqueness.

The default for this option is implementation-defined, so existing
implementations can keep their current behavior.  But at least that's
explicit now.

### ORDER BY in grouped table (F868)

Consider the following tables and query:

```sql
CREATE TABLE product (
    product_id int PRIMARY KEY,
    product_name varchar,
    product_code varchar UNIQUE
);

CREATE TABLE product_part (
    product_id int,
    part_id int,
    num int,
    PRIMARY KEY (product_id, part_id)
);

SELECT product.product_id, sum(product_part.num)
FROM product JOIN product_part ON product.product_id = product_part.product_id
GROUP BY product.product_id
ORDER BY product.product_code;
```

This probably works just fine in most SQL implementations beyond the
most simple ones, but it turned out that this was technically not
allowed.  In particular, it was not allowed to have a grouped table
ordered by a column that is not exposed by the `SELECT` list of the
grouped table.  Now, an SQL implementation can claim to support this
feature if it does allow this.

Again, this is probably not something you need to pay attention to in
practice, but this is the sort of thing that sometimes gets fixed.

### GREATEST and LEAST (T054)

This adds two new functions `GREATEST` and `LEAST`.  These have
already been present in many implementation.

```sql
SELECT greatest(1, 2);  --> 2
SELECT least(1, 2);     --> 1
```

Any number of arguments are supported:

```sql
SELECT greatest(1, 2, 3);  --> 3
SELECT least(1, 2, 3);     --> 1
```

Obviously, this is more interesting with variable data.  You can do
"whichever is more" or "whichever is less" calculations like this:

```sql
SELECT greatest(base_price * 0.10, fixed_fee) FROM data ...
SELECT least(standard, discount) FROM data ...
```

To be clear, in most programming languages, these functions would
merely be called `max` and `min`.  But in SQL, those names are already
used for aggregate functions.  Since there is no syntactic difference
between normal functions and aggregate functions, you have to pick two
different names.

### String padding functions (T055)

This adds two new string functions `LPAD` and `RPAD`.  These are also
already in many implementations.

```sql
SELECT lpad(cast(amount as varchar), 12, '*') FROM ...
```

might result in something like

	****12345.67

The padding character is space by default.

### Multi-character TRIM functions (T056)

Another set of functions already known from existing implementations:
`LTRIM`, `RTRIM`, and `BTRIM`.

Unlike the existing single-character trim function
(`TRIM({LEADING|TRAILING|BOTH} 'x' FROM val)`), which can only trim a
single character, these can trim multiple characters.  They also have
a less obscure syntax, so they might be easier to use in general.

Here is an example that is effectively the inverse of the `lpad` call
above:

```sql
SELECT ltrim(val, '*') ...
```

### Optional string types maximum length (T081)

This allows leaving off the maximum length specification on the
`VARCHAR`/`CHARACTER VARYING` type.  Before, standard SQL required the
length to be specified, so you often see examples with seemingly
arbitrary lengths like

```sql
CREATE TABLE t1 (
    a VARCHAR(1000),
    b VARCHAR(4000),
	...
);
```

Now you can just leave it off:

```sql
CREATE TABLE t1 (
    a VARCHAR,
    b VARCHAR,
	...
);
```

In that case, an implementation-defined default limit will be applied.

Some implementations already had a way to achieve this, but now there
is a standard way to do it.

### Enhanced cycle mark values (T133)

The `CYCLE` clause is a lesser-known feature of recursive queries.  To
detect a cycle in such a query, you can write

```sql
WITH RECURSIVE ... (
    SELECT ...
      UNION ALL
    SELECT ...
)
CYCLE id SET is_cycle TO 'Y' DEFAULT 'N' USING path;
```

This would track cycles based on the `id` column and set the
`is_cycle` column to the specified values if a cycle had been detected
or not.

When recursive queries were added to SQL, there was no `boolean` type,
so the old standard required you to use a character string, like shown
here.  (The actual values shown are not required but typical.)  By
now, there is a `boolean` type, so this can be modernized a bit.  The
new feature in SQL:2023 is that 1) the cycle mark values can be of
type `boolean`, and 2) the actual values can be omitted and will
default to true and false.  So a modernized version of the above query
would look like

```sql
WITH RECURSIVE ... (
    SELECT ...
      UNION ALL
    SELECT ...
)
CYCLE id SET is_cycle USING path;
```

### ANY_VALUE (T626)

This is a new aggregate function `any_value()` that just returns "any
value", meaning an arbitrary, non-null value, from the input set.
This already exists in serveral implementations.  It is mainly used in
analytical databases when writing complex aggregation or windowing
queries.

For example,

```sql
CREATE TABLE t1 (
    a int,
    b int
);

INSERT INTO t1 VALUES (1, 11), (1, 22), (1, 33);

SELECT a, any_value(b) FROM t1 GROUP BY a;
```

could return any of `1 | 11`, `1 | 22`, or `1 | 33`.

### Non-decimal integer literals (T661)

This allows hexadecimal, octal, and binary integer literals, similar
to many programming languages.

```sql
SELECT 0xFFFF, 0o755, 0b11001111 ...
```

### Underscores in numeric literals (T662)

This allows putting underscores into numeric literals for visual
grouping.  Like T661, this is similar to what many programming
languages allow nowadays.

```sql
SELECT ... WHERE a > 1_000_000;
UPDATE ... SET x = 0x_FFFF_FFFF ...
```

## New JSON features

### JSON data type (T801)

There is now a `JSON` data type.  Many implementations already have
this.

SQL:2016 only had JSON operations on JSON data stored in character
string fields.  (This was mainly because time was running out when
SQL:2016 was being finalized.)

This feature code also includes a few other JSON-related pieces of
syntax, such as `JSON_SERIALIZE`, `JSON_SCALAR`, and `IS JSON`.

### Enhanced JSON data type (T802)

As the name suggests, this is additional optional functionality for
the JSON type.  Specifically, it adds a check for unique keys, like
`JSON('...text...' WITH UNIQUE KEYS)`.

### String-based JSON (T803)

This represents the string-based JSON functionality in SQL:2016.  An
implementation that provides JSON functionality such as `JSON_OBJECT`,
`JSON_OBJECTAGG`, `JSON_TABLE`, etc. can choose to support either the
old string-based way (T803), where JSON data is stored in character
string fields, or the new "native" way (T801), where it is stored in
the `JSON` type, or both.

### Hex integer literals in SQL/JSON path language (T840)

This feature allows using hexadecimal integer literals in the SQL/JSON
path language.  The SQL/JSON path language is based on JavaScript,
which already supported hexadecimal literals, but SQL:2016 explicitly
excluded them from SQL/JSON.  Given the arrival of hexadecimal
literals in the SQL language proper (T661), this is now also
optionally allowed in the SQL/JSON path language.

Not part of this feature, but the wording of the SQL standard has also
been updated to allow implementations to track enhancements in the
JavaScript (ECMAScript) language syntax as extensions, without needing
to update the SQL standard every time a new ECMAScript version comes
out.  So SQL/JSON path implementations could now also support other
numeric literal syntax from more recent ECMAScript versions, such as
binary integers and underscore separators.

### SQL/JSON simplified accessor (T860–T864)

The "simplified accessor" group of features allows accessing parts of
JSON values using dot and array syntax as if they were composite types
or arrays.

For example, if you have values in a JSON column `j` like

```json
{"foo": {"bar": [100, 200, 300]}, ...}
```

then with the simplified accessor syntax you can access the pieces
using familiar-looking syntax like

```sql
SELECT t.j.foo.bar[2], ... FROM tbl t ...
```

The semantics of this are defined in terms of `JSON_QUERY` and
`JSON_VALUE` constructions (which have been available since SQL:2016),
so this really just syntactic sugar.

### SQL/JSON item methods (T865–T878)

A number of new so-called item methods, meaning functions or methods
you can apply to SQL/JSON values inside the SQL/JSON language, are
introduced.  SQL:2016 already contained a bunch of these, such as
`abs()`, `floor()`, `size()`.  The new set is focusing on data type
conversions.

* T865: SQL/JSON item method: bigint()
* T866: SQL/JSON item method: boolean()
* T867: SQL/JSON item method: date()
* T868: SQL/JSON item method: decimal()
* T869: SQL/JSON item method: decimal() with precision and scale
* T870: SQL/JSON item method: integer()
* T871: SQL/JSON item method: number()
* T872: SQL/JSON item method: string()
* T873: SQL/JSON item method: time()
* T874: SQL/JSON item method: time_tz()
* T875: SQL/JSON item method: time precision
* T876: SQL/JSON item method: timestamp()
* T877: SQL/JSON item method: timestamp_tz()
* T878: SQL/JSON item method: timestamp precision

### JSON comparison (T879–T882)

These features allow the new `JSON` type to be compared and sorted and
used in grouping operations.  For that, equality and ordering
semantics are defined.

## Property Graph Queries

A whole new part 16 was added to the SQL standard, titled "Property
Graph Queries (SQL/PGQ)".  (Including this new part, there are now 11
active parts of SQL (ISO/IEC 9075).  The part that most people know as
the core language is part 2.)  This allows data in tables to be
queried as if it were a graph database.  This is a complex topic that
would be too much to get into here, but here is a rough idea how this
would look:

```sql
CREATE TABLE person (...);
CREATE TABLE company (...);
CREATE TABLE ownerof (...);
CREATE TABLE transaction (...);
CREATE TABLE account (...);

CREATE PROPERTY GRAPH financial_transactions
    VERTEX TABLES (person, company, account)
    EDGE TABLES (ownerof, transaction);

SELECT owner_name,
       SUM(amount) AS total_transacted
FROM financial_transactions GRAPH_TABLE (
  MATCH (p:person WHERE p.name = 'Alice')
        -[:ownerof]-> (:account)
        -[t:transaction]- (:account)
        <-[:ownerof]- (owner:person|company)
  COLUMNS (owner.name AS owner_name, t_amount AS amount)
) AS ft
GROUP BY owner_name;
```

(In this example, all the tables would need foreign keys between them
so that the property graph definition can find out how they are
connected.  There is also syntax to specify the connections in the
property graph definition if there are no foreign keys.)

In simple cases, this is possibly a more intuitive way to write some
complex join queries.  In other cases, implementations might attempt
to optimize such queries using techniques specific to graph databases.
This is all new and we'll see how it works out in practice.

## Conclusion

It is perhaps curious that the two major enhancements in SQL:2023 are
functionality to integrate with non-relational data management.  I
think this reflects the desire among practitioners to manage more data
in more ways that might be suitable for a particular situation, while
keeping SQL, relational data, and strongly-typed and schema-organized
data at the center.  The core, relational SQL language is pretty
complete, but as can be seen, there is room for usability enhancements
and gentle modernization.

Computer language standards development is much like software
development in that when you ship a version, you are already working
on the next one.  The gap between SQL:2016 and SQL:2023 was the second
longest in SQL history (after 1992–1999).  Normally, ISO/IEC standards
are supposed to take 4 to 5 years (or 3 to 4 years in the future).
The COVID-19 pandemic certainly contributed to the delay, with
disruption to meeting schedules and the work and personal lives of the
participants.  The other reason was probably the size of the SQL/PGQ
project.

What's in the future?  There is not really a roadmap, but from what I
gather, there is likely more PGQ, more JSON, and more polishing of the
core language.  On we go.
