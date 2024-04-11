---
title: "PostgreSQL 17 commitfest conclusion"
comments: true
tags:
- postgresql
---

Last October, I [wrote]({% post_url 2023-10-10-commitfest-throughput %}):

> Looking at the numbers in the PG17 cycle so far, even though they
> are much lower than the 2023-03 commitfest, we can expect that PG17
> will have more activity in total than previous development cycles.

And now it's time to count up the score.  The final per-commitfest
numbers of committed patches were:

<table>

<tr>
<td rowspan="2">PG17</td>
<td><a href="https://commitfest.postgresql.org/43/">2023-07</a></td>
<td><a href="https://commitfest.postgresql.org/44/">2023-09</a></td>
<td><a href="https://commitfest.postgresql.org/45/">2023-11</a></td>
<td><a href="https://commitfest.postgresql.org/46/">2024-01</a></td>
<td><a href="https://commitfest.postgresql.org/47/">2024-03</a></td>
</tr>
<tr>
<td>87</td><td>68</td><td>86</td><td>75</td><td>134</td>
</tr>

</table>

The 01 and 03 numbers are all-time highs for their respective months.

The total numbers of committed patches registered in a commitfest for
a development cycle were:

<table>

<tr>
<td>PG12</td>
<td>319</td>
</tr>

<tr>
<td>PG13</td>
<td>277</td>
</tr>

<tr>
<td>PG14</td>
<td>360</td>
</tr>

<tr>
<td>PG15</td>
<td>349</td>
</tr>

<tr>
<td>PG16</td>
<td>433</td>
</tr>

<tr>
<td>PG17</td>
<td>450</td>
</tr>

</table>

So this went pretty much as I had suspected back in October.

Of course, some people [aren't
happy](https://www.postgresql.org/message-id/flat/Zfer8VcFeL5ZSP1A%40paquier.xyz)
with the last minute rush.  We can see how commit activity peaked in
the last week (keeping in mind that 2024-04-08 was feature freeze):

```
git log --since='2024-03-01' --until='2024-04-09' --format='%cd' --date='format:%V' master | sort | uniq -c

     ...
     82 10   # week starting 2024-03-04
     82 11   # week starting 2024-03-11
     73 12   # week starting 2024-03-18
     72 13   # week starting 2024-03-25
    123 14   # week starting 2024-04-01
    ...
```

I look forward to checking how that works out when we look at the
final release [statistics]({% post_url
2022-10-25-postgresql-15-statistics %}) such as number of release note
items and number of contributors.
