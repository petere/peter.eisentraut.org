---
layout: post
title: "PostgreSQL 15 statistics"
comments: true
tags:
- postgresql
---

I have been gathering some statistics about each major PostgreSQL
release.  Here is the update for this year:

|                          | PostgreSQL 15 (2022) | PostgreSQL 14 (2021) | PostgreSQL 13 (2020) | PostgreSQL 12 (2019) |
|--------------------------|----------------------|----------------------|----------------------|
| changes listed in release notes |  189 |  229 |  183 |  197 |
| commits                  | 2472 | 2702 | 2233 | 2429 |
| contributors listed in release notes |  412 |  415 |  380 |  410 |
| total files              | 6114 | 5951 | 5688 | 5558 |
| SLOC                     | 1,077,633 | 1,045,222 | 1,024,657 | 990,405 |
| files changed            | 3872 | 3764 | 3503 | 3429 |

Looking at these figures, it seems that the capacity of the PostgreSQL
development team is somehow fixed.  Now, one could think that this is
a problem and that we might want to grow more.  On the other hand, I
have done similar analyses many times over the years, and the upshot
was similar, and yet PostgreSQL continues to grow in use and
popularity, so maybe it's not all wrong.

One thing to note is that we are also adding code (files and lines) at
a constant rate, which could increase the general maintenance cost in
the long run, which could be a problem if we have a team with a
non-growing capacity.  So any efforts that facilitate code
maintenance, including refactoring, deleting unused code and features,
updating tooling, improving test performance, and modernizing the
build system, continue to be necessary.  Of course, if you think about
it, this is already factored into these figures: If the code base is
growing every year, yet we continue to produce new things at a
constant rate while maintaining the existing code, the effective
output of the team is also growing over time.

---

Details on how the numbers were derived:

(in each case, as of `REL_15_0` tag, and analogously for other
releases)

- changes listed in release notes: `grep '<listitem>'
  doc/src/sgml/release-15.sgml | wc -l` (This possibly counts the
  "major items" at the top double, but it's close enough.)

- commits: `git log --oneline REL_14_STABLE..REL_15_0 | wc -l`

- contributors listed in release notes: `grep '<member>'
  doc/src/sgml/release-15.sgml | wc -l`

- files: `git ls-files | wc -l`

- SLOC: `sloccount --addlangall .` (after `git clean -fdx`)

- files changed: `git diff REL_14_STABLE...REL_15_0 --name-only | wc -l`
