---
layout: post
title: "Storing URIs in PostgreSQL"
date: 2015-04-16 20:00:00 -0400
comments: true
tags:
- uri
- pguri
- postgresql
---

About two months ago, this happened:

<blockquote class="twitter-tweet" lang="en"><p>What form of bribery would be required to convince someone to write an `email` and `url` data type for Postgres, by the way? Any takers?</p>&mdash; Peter van Hardenberg (@pvh) <a href="https://twitter.com/pvh/status/567395527357001728">February 16, 2015</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

And a few hours later:

<blockquote class="twitter-tweet" data-conversation="none" data-cards="hidden" lang="en"><p><a href="https://twitter.com/pvh">@pvh</a> <a href="https://t.co/NNxHRsHudz">https://t.co/NNxHRsHudz</a></p>&mdash; Peter Eisentraut (@petereisentraut) <a href="https://twitter.com/petereisentraut/status/567902299194073089">February 18, 2015</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

It took a few more hours and days after this to refine some details,
but I have now tagged the first
[release](https://github.com/petere/pguri/releases/tag/1.20150415) of
this extension.  Give it a try and let me know what you think.  Bug
reports and feature requests are welcome.

(I chose to name the data type `uri` instead of `url`, as originally
suggested, because that is more correct and matches what the parsing
library calls it.  One could create a domain if one prefers the other
name or if one wants to restrict the values to certain kinds of URIs
or URLs.)

(If you are interested in storing email addresses,
[here](https://wiki.postgresql.org/wiki/Email_address_parsing) is an
idea.)
