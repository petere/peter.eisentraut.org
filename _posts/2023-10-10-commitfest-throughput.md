---
title: "Commitfest throughput"
comments: true
tags:
- postgresql
---

I just finished a stint as commitfest manager for the September (<a
href="https://commitfest.postgresql.org/44/">2023-09</a>) <a
href="https://wiki.postgresql.org/wiki/CommitFest">commitfest</a> of
the PostgreSQL project.  After the conclusion, I of course looked at
the statistics and saw that 68 patches had been committed, which I
felt was low.  But then I looked a bit into the past and noticed an
interesting pattern: Since the beginning of the current
five-commitfest system, the September commitfest almost always has the
lowest number of commits.

Consider the number of patches with status "Committed" after each
commitfest:

<table>
<tr>
<td rowspan="2">PG12</td>
<td><a href="https://commitfest.postgresql.org/18/">2018-07</a></td>
<td><a href="https://commitfest.postgresql.org/19/">2018-09</a></td>
<td><a href="https://commitfest.postgresql.org/20/">2018-11</a></td>
<td><a href="https://commitfest.postgresql.org/21/">2019-01</a></td>
<td><a href="https://commitfest.postgresql.org/22/">2019-03</a></td>
</tr>
<tr>
<td>55</td><td><strong>46</strong></td><td>60</td><td>58</td><td>100</td>
</tr>

<tr>
<td rowspan="2">PG13</td>
<td><a href="https://commitfest.postgresql.org/23/">2019-07</a></td>
<td><a href="https://commitfest.postgresql.org/24/">2019-09</a></td>
<td><a href="https://commitfest.postgresql.org/25/">2019-11</a></td>
<td><a href="https://commitfest.postgresql.org/26/">2020-01</a></td>
<td><a href="https://commitfest.postgresql.org/27/">2020-03</a></td>
</tr>
<tr>
<td>64</td><td>39</td><td><strong>35</strong></td><td>49</td><td>90</td>
</tr>

<tr>
<td rowspan="2">PG14</td>
<td><a href="https://commitfest.postgresql.org/28/">2020-07</a></td>
<td><a href="https://commitfest.postgresql.org/29/">2020-09</a></td>
<td><a href="https://commitfest.postgresql.org/30/">2020-11</a></td>
<td><a href="https://commitfest.postgresql.org/31/">2021-01</a></td>
<td><a href="https://commitfest.postgresql.org/32/">2021-03</a></td>
</tr>
<tr>
<td>65</td><td><strong>48</strong></td><td>69</td><td>56</td><td>122</td>
</tr>

<tr>
<td rowspan="2">PG15</td>
<td><a href="https://commitfest.postgresql.org/33/">2021-07</a></td>
<td><a href="https://commitfest.postgresql.org/34/">2021-09</a></td>
<td><a href="https://commitfest.postgresql.org/35/">2021-11</a></td>
<td><a href="https://commitfest.postgresql.org/36/">2022-01</a></td>
<td><a href="https://commitfest.postgresql.org/37/">2022-03</a></td>
</tr>
<tr>
<td>81</td><td><strong>54</strong></td><td>58</td><td>58</td><td>98</td>
</tr>

<tr>
<td rowspan="2">PG16</td>
<td><a href="https://commitfest.postgresql.org/38/">2022-07</a></td>
<td><a href="https://commitfest.postgresql.org/39/">2022-09</a></td>
<td><a href="https://commitfest.postgresql.org/40/">2022-11</a></td>
<td><a href="https://commitfest.postgresql.org/41/">2023-01</a></td>
<td><a href="https://commitfest.postgresql.org/42/">2023-03</a></td>
</tr>
<tr>
<td>77</td><td><strong>65</strong></td><td>94</td><td>70</td><td>127</td>
</tr>

<tr>
<td rowspan="2">PG17</td>
<td><a href="https://commitfest.postgresql.org/43/">2023-07</a></td>
<td><a href="https://commitfest.postgresql.org/44/">2023-09</a></td>
<td><a href="https://commitfest.postgresql.org/45/">2023-11</a></td>
<td><a href="https://commitfest.postgresql.org/46/">2024-01</a></td>
<td><a href="https://commitfest.postgresql.org/47/">2024-03</a></td>
</tr>
<tr>
<td>87</td><td><strong>68</strong></td><td>tbd.</td><td>tbd.</td><td>tbd.</td>
</tr>

</table>


Here is a similar statistic directly from the Git repository: The
number of commits per month, over the last five years, which covers
approximately the same time interval as above.

```
$ git log --since='2018-10-01' --until='2023-10-01' --format='%ad' --date='format:%m' master | sort | uniq -c
    953 01
    819 02
   1395 03
   1258 04
    853 05
    738 06
   1052 07
    864 08
    922 09
    771 10
    949 11
    701 12
```

You can see here that the commitfest months (01, 03, 07, 09, 11) have
higher numbers than their neighboring months, and among those
commitfest months, September has the lowest number.

I don't quite understand the reasons for this.  Intuitively, you could
make arguments why some of the other times of the year should see
lower activity (holidays? vacation?).  But in any case, it is good to
keep this in mind when assessing commitfest throughput.  Looking at
the numbers in the PG17 cycle so far, even though they are much lower
than the 2023-03 commitfest, we can expect that PG17 will have more
activity in total than previous development cycles.
