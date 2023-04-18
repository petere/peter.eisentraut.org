---
title: "PostgreSQL and SQL:2023"
comments: true
tags:
- postgresql
- sql
---

In a [previous article]({% post_url
2023-04-04-sql-2023-is-finished-here-is-whats-new %}), I introduced
what is new in SQL:2023.  Now I want to show the status of SQL:2023
support in PostgreSQL.  See the previous article for details on these
features.

|-------------------------------------------------------|--------------------|
| UNIQUE null treatment (F292)                          | [PostgreSQL 15](https://www.postgresql.org/docs/15/release-15.html) |
| ORDER BY in grouped table (F868)                      | ancient            |
| GREATEST and LEAST (T054)                             | ancient            |
| String padding functions (T055)                       | ancient            |
| Multi-character TRIM functions (T056)                 | ancient            |
| Optional string types maximum length (T081)           | ancient            |
| Enhanced cycle mark values (T133)                     | [PostgreSQL 14](https://www.postgresql.org/docs/14/release-14.html) |
| ANY_VALUE (T626)                                      | PostgreSQL 16      |
| Non-decimal integer literals (T661)                   | PostgreSQL 16      |
| Underscores in numeric literals (T662)                | PostgreSQL 16      |
| JSON data type (T801)                                 | PostgreSQL [9.2](https://www.postgresql.org/docs/9.2/release-9-2.html)/[9.4](https://www.postgresql.org/docs/9.4/release-9-4.html) |
| Enhanced JSON data type (T802)                        | future             |
| String-based JSON (T803)                              | not planned        |
| Hex integer literals in SQL/JSON path language (T840) | PostgreSQL 16      |
| SQL/JSON simplified accessor (T860–T864)              | future             |
| SQL/JSON item methods (T865–T878)                     | future             |
| JSON comparison (T879–T882)                           | [PostgreSQL 9.4](https://www.postgresql.org/docs/9.4/release-9-4.html) |
| Property Graph Queries                                | future             |

Notes:

* "ancient" means sometime before PostgreSQL 10.  These are features
  that were already widely available in SQL implementations before
  they were added to the standard.

* As of this writing, PostgreSQL 16 is in feature freeze but not
  released yet.  So those entries could in theory change, but it's
  pretty unlikely.  Conformance information for PostgreSQL 16 relative
  to SQL:2023 can also be found in the
  [documentation](https://www.postgresql.org/docs/devel/features.html).

* For the T801 entry, the `json` type was added in PostgreSQL 9.2 and
  the `jsonb` type was added in PostgreSQL 9.4.  Most of the JSON
  functionality in SQL:2016 and SQL:2023 (including features T879 ff.)
  maps more readily to the `jsonb` type, so this information should be
  interpreted that way.  Whether and how the `json` and `jsonb` types
  should be consolidated in PostgreSQL is an open question.

* "not planned" is my opinion that the feature is essentially obsolete
  (see previous article) and not worth implementing.

* "future" is my opinion that the feature could be a sensible addition
  to PostgreSQL, but there is no concrete work in progress.
