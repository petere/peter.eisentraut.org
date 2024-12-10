---
title: "Where are all the PostgreSQL users?"
comments: true
tags:
- postgresql
---

Let's stipulate that PostgreSQL has grown significantly in popularity
over the last 20 years.  I don't know by how much, but certainly at
least one order of magnitude, probably two or more.

It used to be the case that if you were a PostgreSQL user and wanted
to interact with other PostgreSQL users and perhaps developers (which
was a more fluent distinction back then), you'd hang out on mailing
lists such as
[pgsql-general](https://www.postgresql.org/list/pgsql-general/) and
maybe lurk a bit and answer questions and ask your own.  There are a
few such mailing lists, such as pgsql-general,
[pgsql-sql](https://www.postgresql.org/list/pgsql-sql/),
[pgsql-admin](https://www.postgresql.org/list/pgsql-admin/), but back
then, that was basically it, that was the pretty much the whole world
of PostgreSQL users hanging out and sharing knowledge.  There was no
other place.

One advantage of having this concentrated in one or a few related
places is that it was easy to pick the place to hang out in.  You'd be
sure that if there was anywhere to get an answer or to learn
something, this was the one.  Also, for the developers, this was an
easy and useful way to monitor user feedback and to engage with users,
because you could just read along on a few mailing lists to get the
entirety of user discussions about the product.

But I don't think it works like that anymore.

Traffic on user mailing lists is down.  In November 2004, there were
1507 messages on pgsql-general.  In November 2024, there were
only 445.  (By contrast, traffic on
[pgsql-hackers](https://www.postgresql.org/list/pgsql-hackers/) was up
2279 versus 1300.)  This is just one example; you can pick any
combination of time intervals of the above-mentioned mailing lists to
get similar results.  Make a chart out of it to make it more
depressing.

Where are all the users now?

Certainly, users still want to ask questions and other users still
want to hang out with users and share knowledge.

Of course, we know the answer: They are on [Stack
Overflow](https://stackoverflow.com/questions/tagged/postgresql),
[Reddit](https://www.reddit.com/r/PostgreSQL/), Slack, Telegram,
Discord, Mastodon, and so on and so on.  I don't even know the whole
list.  Is there a whole list?  There are also non-text media that
didn't really exist in that way in say 2004: YouTube, podcasts, or
in-person conferences.  There are many options now.

Do these places give you the same community experience as before?  Do
they each have enough critical mass that each one is viable on their
own and doesn't force users to subscribe to a bunch of them?

Or here's a question: Are there enough options where you can
participate with some level of privacy or anonymity?

I am now firmly a PostgreSQL developer, no longer really a PostgreSQL
user.  From the perspective of a developer, I wonder: Do these new
discussion places allow interaction with developers?  Do they allow
interested users to become interested in becoming a developer
themselves?  As a developer, where should I look to monitor user vibe
and feedback?

On pgsql-hackers, we sometimes say things like, nobody has ever
requested that, or, we have only seen three such cases in ten years.
And we have the records to prove it.  But if the mailing lists
represent only a fraction of users overall and a fraction of users who
want to interact in public, what kind of data is that?

And also, if another system became or were the dominant discussion
platform, would it allow us to keep publicly available archives, or is
it at the whim of some company that might change business plans in
five years and take everything away?

Of course, this development is not special to PostgreSQL.  Many
open-source projects that came up in the mailing-list era are surely
facing similar situations.

What can we do?  I don't mind that there is diversity in the way of
interacting with other users and enthusiasts.  Some competition is
good.  But I think the project should provide and own at least one of
the options that people actually want to use.
