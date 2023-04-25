---
title: "CREATE commands in PostgreSQL releases"
comments: true
tags:
- postgresql
---

Here is a fun little view on the progress of PostgreSQL.  Consider the
number of "CREATE SOMETHING" commands each release contains.  As more
features are added over time, more such CREATE commands are added.

| Release              | Number | New                                                                        |
|----------------------|--------|----------------------------------------------------------------------------|
| PostgreSQL&nbsp;16   | 42     |                                                                            |
| PostgreSQL&nbsp;15   | 42     |                                                                            |
| PostgreSQL&nbsp;14   | 42     |                                                                            |
| PostgreSQL&nbsp;13   | 42     |                                                                            |
| PostgreSQL&nbsp;12   | 42     |                                                                            |
| PostgreSQL&nbsp;11   | 42     | PROCEDURE                                                                  |
| PostgreSQL&nbsp;10   | 41     | PUBLICATION, STATISTICS, SUBSCRIPTION                                      |
| PostgreSQL&nbsp;9.6  | 38     | ACCESS METHOD                                                              |
| PostgreSQL&nbsp;9.5  | 37     | POLICY, TRANSFORM                                                          |
| PostgreSQL&nbsp;9.4  | 35     |                                                                            |
| PostgreSQL&nbsp;9.3  | 35     | EVENT TRIGGER, MATERIALIZED VIEW                                           |
| PostgreSQL&nbsp;9.2  | 33     |                                                                            |
| PostgreSQL&nbsp;9.1  | 33     | COLLATION, EXTENSION                                                       |
| PostgreSQL&nbsp;9.0  | 31     |                                                                            |
| PostgreSQL&nbsp;8.4  | 31     | FOREIGN DATA WRAPPER, SERVER, USER MAPPING                                 |
| PostgreSQL&nbsp;8.3  | 28     | OPERATOR FAMILY, TEXT SEARCH {CONFIGURATION, DICTIONARY, PARSER, TEMPLATE} |
| PostgreSQL&nbsp;8.2  | 23     |                                                                            |
| PostgreSQL&nbsp;8.1  | 23     | ROLE                                                                       |
| PostgreSQL&nbsp;8.0  | 22     | TABLESPACE                                                                 |
| PostgreSQL&nbsp;7.4  | 21     |                                                                            |
| PostgreSQL&nbsp;7.3  | 21     | CAST, CONVERSION, DOMAIN, OPERATOR CLASS, SCHEMA                           |
| PostgreSQL&nbsp;7.2  | 16     |                                                                            |
| PostgreSQL&nbsp;7.1  | 16     |                                                                            |
| PostgreSQL&nbsp;7.0  | 16     | CONSTRAINT, GROUP                                                          |
| PostgreSQL&nbsp;6.5  | 14     |                                                                            |
| PostgreSQL&nbsp;6.4  | 14     |                                                                            |
| PostgreSQL&nbsp;6.3  | 14     | LANGUAGE, TABLE AS, USER                                                   |
| PostgreSQL&nbsp;6.2  | 11     | TRIGGER                                                                    |
| PostgreSQL&nbsp;6.1  | 10     | SEQUENCE                                                                   |
| PostgreSQL&nbsp;6.0  | 9      |                                                                            |
| Postgres95&nbsp;1.01 | 9      | AGGREGATE, DATABASE, FUNCTION, INDEX, OPERATOR, RULE, TABLE, TYPE, VIEW    |

(These are counted by what commands have a separate man page, which is
why for example "CREATE TABLE AS" is counted separately.  Before
PostgreSQL 6.4, the documentation was organized differently, so those
numbers are reconstructed from the grammar source code.)

We can also look at the number of system catalogs.  Often, a new
"CREATE SOMETHING" command also comes with a new system catalog
("pg_something") to store metadata about what it is creating.  But new
system catalogs can also appear as part of extensions to existing
features.

| Release             | Number | New/(Removed)                                                                                                                               |
|---------------------|--------|---------------------------------------------------------------------------------------------------------------------------------------------|
| PostgreSQL&nbsp;16  | 64     |                                                                                                                                             |
| PostgreSQL&nbsp;15  | 64     | `pg_parameter_acl`, `pg_publication_namespace`                                                                                              |
| PostgreSQL&nbsp;14  | 62     |                                                                                                                                             |
| PostgreSQL&nbsp;13  | 62     | (`pg_pltemplate`)                                                                                                                           |
| PostgreSQL&nbsp;12  | 63     | `pg_statistic_ext_data`                                                                                                                     |
| PostgreSQL&nbsp;11  | 62     |                                                                                                                                             |
| PostgreSQL&nbsp;10  | 62     | `pg_partitioned_table`, `pg_publication`, `pg_publication_rel`, `pg_sequence`, `pg_statistic_ext`, `pg_subscription`, `pg_subscription_rel` |
| PostgreSQL&nbsp;9.6 | 55     | `pg_init_privs`                                                                                                                             |
| PostgreSQL&nbsp;9.5 | 54     | `pg_policy`, `pg_replication_origin`, `pg_transform`                                                                                        |
| PostgreSQL&nbsp;9.4 | 51     |                                                                                                                                             |
| PostgreSQL&nbsp;9.3 | 51     | `pg_event_trigger`                                                                                                                          |
| PostgreSQL&nbsp;9.2 | 50     | `pg_range`, `pg_shseclabel`                                                                                                                 |
| PostgreSQL&nbsp;9.1 | 48     | `pg_collation`, `pg_extension`, `pg_foreign_table`, `pg_seclabel`                                                                           |
| PostgreSQL&nbsp;9.0 | 44     | `pg_db_role_setting`, `pg_default_acl`, `pg_largeobject_metadata`, (`pg_listener`)                                                          |
| PostgreSQL&nbsp;8.4 | 42     | `pg_foreign_data_wrapper`, `pg_foreign_server`, `pg_user_mapping`, (`pg_autovacuum`)                                                        |
| PostgreSQL&nbsp;8.3 | 40     | `pg_enum`, `pg_opfamily`, `pg_ts_config`, `pg_ts_config_map`, `pg_ts_dict`, `pg_ts_parser`, `pg_ts_template`                                |
| PostgreSQL&nbsp;8.2 | 33     | `pg_shdescription`                                                                                                                          |
| PostgreSQL&nbsp;8.1 | 32     | `pg_auth_members`, `pg_authid`, `pg_autovacuum`, `pg_pltemplate`, `pg_shdepend`, (`pg_group`), (`pg_shadow`), (`pg_version`)                |
| PostgreSQL&nbsp;8.0 | 30     | `pg_tablespace`                                                                                                                             |
| PostgreSQL&nbsp;7.4 | 29     |                                                                                                                                             |
| PostgreSQL&nbsp;7.3 | 29     | `pg_cast`, `pg_constraint`, `pg_conversion`, `pg_depend`, `pg_namespace`, (`pg_relcheck`)                                                   |
| PostgreSQL&nbsp;7.2 | 25     | (`pg_inheritproc`), (`pg_ipl`), (`pg_log`), (`pg_variable`)                                                                                 |
| PostgreSQL&nbsp;7.1 | 29     | `pg_largeobject`                                                                                                              |
| PostgreSQL&nbsp;7.0 | 28     |                                                                                                                                             |
| PostgreSQL&nbsp;6.5 | 28     | (`pg_parg`)                                                                                                                                 |
| PostgreSQL&nbsp;6.4 | 29     |                                                                                                                                             |
| PostgreSQL&nbsp;6.3 | 29     | `pg_description`, (`pg_defaults`), (`pg_demon`), (`pg_hosts`), (`pg_magic`), (`pg_server`), (`pg_time`)                                     |
| PostgreSQL&nbsp;6.2 | 34     | `pg_attrdef`, `pg_relcheck`, `pg_trigger`                                                                                                   |
| PostgreSQL&nbsp;6.1 | 31     |                                                                                                                                             |
| PostgreSQL&nbsp;6.0 | 31     |                                                                                                                                             |
| Postgre95&nbsp;1.01 | 31     |                                                                                                                                             |

Note here that before approximately PostgreSQL 7.0, things get a bit
murky, since there are catalogs releated to features that didn't
really work (anymore) at the time, or things that are named like
catalogs but are really something else (such as `pg_control`), so the
exact counts might be debatable.
