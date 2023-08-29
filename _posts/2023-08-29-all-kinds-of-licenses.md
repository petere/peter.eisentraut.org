---
title: "All kinds of licenses"
comments: true
tags:
- postgresql
---

After the recent news that HashiCorp has [changed the
licenses](https://www.hashicorp.com/blog/hashicorp-adopts-business-source-license)
of its hitherto-open-source products, I thought it would be a good
time to take a look at the licenses that have sprung up around
PostgreSQL and adjacent and related communities, since quite a bit has
changed there recently, and it's hard to keep track.

(Maybe HashiCorp is not really directly adjacent to PostgreSQL, but
the license it chose (see below) came from the database space.  Also,
there is some overlap of users.)

_Disclaimer: I work for [EDB](https://www.enterprisedb.com/), which
produces PostgreSQL-based software, some of which is open-source and
some of which is closed-source/proprietary. Some of the companies
listed below could be considered competitors._

## Overview

Here is my understanding of the current licensing situation of various
projects and companies:

|-----------------------------------------------|-----------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------|
| Project/Company                               | Current license             | Notes                                                                                                                                                                      | Source code link                                                                                                                                        |
|-----------------------------------------------|-----------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Cassandra](https://cassandra.apache.org/)    | Apache 2                    | part of Apache Software Foundation                                                                                                                                         | <https://github.com/apache/cassandra>                                                                                                                   |
| [Citus](https://www.citusdata.com/)           | AGPL 3                      | [previously partially closed-source](https://www.citusdata.com/blog/2022/09/12/distributed-postgres-goes-full-open-source-with-citus)                                      | <https://github.com/citusdata/citus>                                                                                                                    |
| [Confluent](https://www.confluent.io/)        | Confluent Community License | only applies to "Confluent Platform", not the contained Apache Kafka; [announcement](https://www.confluent.io/blog/license-changes-confluent-platform/)                    | <https://github.com/confluentinc/ksql> (for example)                                                                                                    |
| [Elastic](https://www.elastic.co/)            | SSPL / Elastic / Apache 2   | first moved from Apache to custom Elastic License, later adopted SSPL; [LICENSE.txt](https://github.com/elastic/elasticsearch/blob/main/LICENSE.txt)                       | <https://github.com/elastic/elasticsearch>                                                                                                              |
| [HashiCorp](https://www.hashicorp.com/)       | BSL                         | previously MPL; [Licensing FAQ](https://www.hashicorp.com/license-faq)                                                                                                     | <https://github.com/hashicorp/consul> (for example)                                                                                                     |
| [MariaDB](https://mariadb.com/)               | GPL 2, BSL                  | GPL inherited from MySQL, BSL only for certain add-on products; [Licensing FAQ](https://mariadb.com/kb/en/licensing-faq/), [BSL FAQ](https://mariadb.com/bsl-faq-mariadb/) | <https://github.com/MariaDB/server> (GPL), <https://github.com/mariadb-corporation/MaxScale> (BSL)                                                      |
| [MongoDB](https://www.mongodb.com/)           | SSPL                        | previously AGPL 3                                                                                                                                                          | <https://github.com/mongodb/mongo>                                                                                                                      |
| [MySQL](https://www.mysql.com/)               | GPL 2                       | or [proprietary](https://www.mysql.com/about/legal/licensing/oem/)                                                                                                         | <https://github.com/mysql/mysql-server>                                                                                                                 |
| [Neo4j](https://neo4j.com/)                   | GPL 3                       | or [proprietary](https://neo4j.com/licensing/)                                                                                                                             | <https://github.com/neo4j/neo4j>                                                                                                                        |
| [Neon](https://neon.tech/)                    | Apache 2                    |                                                                                                                                                                            | <https://github.com/neondatabase/neon>                                                                                                                  |
| [Oriole](https://www.orioledata.com/)         | PostgreSQL                  |                                                                                                                                                                            | <https://github.com/orioledb/orioledb>                                                                                                                  |
| [pgEdge](https://www.pgedge.com/)             | Confluent Community License | actually labeled "[pgEdge Community License Agreement](https://www.pgedge.com/communitylicense)", but it's the same as Confluent                                           | <https://github.com/pgEdge/spock>                                                                                                                       |
| [Redis](https://redis.io/docs/about/license/) | BSD, SSPL, RSAL             | SSPL and RSAL only for certain add-ons; [information](https://redis.io/docs/about/license/)                                                                                | <https://github.com/redis/redis> (BSD), <https://github.com/RedisInsight/RedisInsight> (SSPL), <https://github.com/redis-stack/redis-stack> (SSPL/RSAL) |
| [Supabase](https://supabase.com/)             | Apache 2                    |                                                                                                                                                                            | <https://github.com/supabase/supabase>                                                                                                                  |
| [Timescale](https://www.timescale.com/)       | TSL, Apache 2               | [information](https://docs.timescale.com/about/latest/timescaledb-editions/); note that the "Community Edition" is the TSL (non-open-source) one                           | <https://github.com/timescale/timescaledb>                                                                                                              |

It's important to note that in some cases, the new license applies to
most or all of the product stack (such as in the cases of MongoDB and
presumably HashiCorp), whereas in many cases, it only applies to
certain add-on products (such as in the cases of Confluent and Redis).
You really need to check the details.  The source code links above go
to the actual source code repositories with the license information in
them.

## Licenses

Now let's do a not-legally-rigorous summary of what these licenses
mean.

### Open source

First, here are licenses mentioned that are [recognized as open-source
licenses](https://opensource.org/licenses/):

[**BSD**](https://opensource.org/license/bsd-3-clause/)
: This license only requires that derivative works maintain the
  copyright notice and license text.  Otherwise, you can do pretty
  much anything with the code, including incorporating it into
  proprietary code or differently-licensed open-source code.

[**PostgreSQL**](https://opensource.org/license/postgresql/)
: This is the same as the BSD license in practice.

[**Apache 2**](https://opensource.org/license/apache-2-0/)
: This license is permissive like the BSD license, but has additional
  terms about patents.

[**MPL**](https://opensource.org/license/mpl-2-0/)
: This license requires that in derived works, changes to the files
  covered under the MPL must be made available.  But it permits
  combination with code under other licenses, and the MPL requirements
  only apply to files originally covered under the MPL.  (This is
  often described as a middle ground between the BSD and GPL
  licenses.)

[**GPL 2**](https://opensource.org/license/gpl-2-0/)
: This license requires that all derived works are also published
  under the same license and that any recipient of a derived work also
  gets the source code.

[**GPL 3**](https://opensource.org/license/gpl-3-0/)
: This is the newer version of the GPL that has additional conditions
  dealing with DRM and patents.  For most practical purposes it is the
  same as the GPL 2.

[**AGPL 3**](https://opensource.org/license/agpl-v3/)
: This is like the GPL 3 with the additional condition that when you
  provide the software as a network service, you need to provide any
  modifications for download.  This was a first attempt to address
  software provided as a service.  It's purpose was to preserve the
  rights that the GPL would give you.  Since software provided as a
  service is not "distributed" in the sense of the GPL, it expands the
  requirements to software provided as a service.

### Other

These are licenses that are not recognized as open-source but are
sometimes categorized as "source-available" licenses, since you can
still get access to the source code, but don't have all the rights of
an open-source license:

[**SSPL**](https://www.mongodb.com/licensing/server-side-public-license)
: This is a license based on the AGPL 3.  The AGPL 3 requires that if
  you offer the software as a service, you need to make any
  modifications to the licensed software available for download.  The
  change in the SSPL is that you need to make all the software that is
  used to provide the service available for download, not just the
  licensed software.  Which would basically require a cloud provider
  to publish the entirety of their internal source code, which might
  be nice for users, but clearly untenable for most providers.

  This license was created by MongoDB, but has since found further
  adoption.

[**BSL**](https://mariadb.com/bsl11/)
: This license essentially says, you can have the source code, you can
  make changes in the source code, and you can use the software, but
  not in production.  But after four years from publication, the
  software becomes available as under the GPL.  This means, when the
  software is new (not yet four years old), you can try it out, but if
  you want to use it in production, you must obtain a different
  license from the vendor, presumably for a fee.

  This license was created by MariaDB.  Note that the "Change License"
  can be chosen by the licensor.  The default, used by MariaDB, is the
  GPL, but HashiCorp uses the MPL (which is what HashiCorp's software
  was licensed under before the change to BSL).

[**Confluent Community License**](https://www.confluent.io/confluent-community-license/)
: "This new license allows you to freely download, modify, and
  redistribute the code (very much like Apache 2.0 does), but it does
  not allow you to provide the software as a SaaS offering
  (e.g. KSQL-as-a-service)."  Actually, this license reads pretty much
  like a BSD license, with the express "excluded purpose" of offering
  the software "-as-a-service".

The above three appear to have gotten some traction outside of the
companies that originally created and used them, and in some cases it
was explicitly intended like that.  So they could be considered
standard licenses by now.

Then there are a few licenses among the ones mentioned in the table
above that have only seen one-off use so far:

[**Elastic License**](https://www.elastic.co/licensing/elastic-license)
: This license was written for Elasticsearch.  It has since been
  replaced by the SSPL.  This custom license is very restrictive and
  really just a small step down from a full proprietary license but
  that you can get the source code to look at (but not change it).

[**RSAL**](https://redis.com/legal/rsalv2-agreement/)
: This stands for "Redis Source Available License".  It is used for
  some Redis-related products.  This appears similar in purpose to the
  Confluent license.  You can do pretty much anything with the
  software except make it available as a service to others.

[**TSL**](https://www.timescale.com/legal/licenses)
: This stands for "Timescale License".  This is a custom license
  written by Timescale for its own product.  It's hard to classify
  this as, "it's just like this other license but with a cloud
  restriction", but I think the closest is that it's a lot like the
  very permissive open-source licenses in that you can view and change
  the code and use it internally and distribute it without providing
  the changed source code, but you can't run it as a cloud service.
  (This is for the [version 2
  license](https://www.timescale.com/blog/building-open-source-business-in-cloud-era-v2/),
  which is more permissive that than the first version.)

## Conclusion

Obviously, the issue here is that a lot of people don't like these new
"source available" licenses.  There is a discussion to be had there.
But at least there is some emergent standardization happening in this
space, so that you only have to know a handful of licenses to
understand what you are getting.
