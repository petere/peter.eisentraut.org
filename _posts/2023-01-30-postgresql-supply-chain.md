---
title: "PostgreSQL supply chain"
excerpt_separator: <!--more-->
comments: true
tags:
- postgresql
---

If you are an application developer and you build on PostgreSQL, then
maybe you have looked into where PostgreSQL comes from, who develops
it, and where you can get professional help if needed.

Now, if you are a PostgreSQL developer (hi!), do you know what you are
building on, where those things come from, who develops them, and
where you get get professional help if needed?

<!--more-->

Consider the [dependency diagram of the internet](https://xkcd.com/2347):

<p align="center">
<img src="https://imgs.xkcd.com/comics/dependency.png"/>
</p>

PostgreSQL is perhaps one of the bigger boxes in the middle.  But what
are the shapes of the boxes below it?

Some are okay: Well-known projects with robust communities and
ecosystems, such as Perl, Python, ICU, LLVM, systemd; those are big
boxes.  There is also OpenSSL, which in a well-publicized case was at
point was one of those thin boxes, but that's been rectified.  There
are lz4 and zstd, somewhat new arrivals in the dependencies of
PostgreSQL, which appear to have active communities in their
respective GitHub projects.  There is also zlib, which is in
maintaince mode but still putting out regular releases.  This is all
fine.

There is some stuff in the murky middle that I'm too lazy to look
into.  Who maintains libkrb5 and libldap and libpam these days?  I
guess these libraries are probably used widely enough that someone
will care, and maybe at the end of the day with a support contract
someone like Red Hat will be on the hook.

But there are also the rather thin sticks propping up PostgreSQL (and
many other things):

* The entire documentation toolchain (docbook-xml, docbook-xsl,
  libxml, libxslt, xsltproc) is in low to no maintenance mode.  I
  discussed this in more detail in [my
  presentation](https://video.fosdem.org/2021/D.docs/ttdpostgresdocbook.webm)
  at FOSDEM 2021.

* GNU Gettext is being maintained, but just barely.  I would love some
  action there.  Here is a [feature
  request](https://savannah.gnu.org/bugs/?56910), for example.  How
  can we help?  I will talk about this in [my
  presentation](https://fosdem.org/2023/schedule/event/translations_20_years_with_gettext/)
  at FOSDEM 2023.

* The TAP tests in PostgreSQL rely on the Perl module
  [IPC::Run](https://metacpan.org/pod/IPC::Run), which by the way is
  explicitly looking for a new maintainer!

* Autoconf is without consistent maintenance now.  Here is a great
  [writeup](https://www.owlfolio.org/development/autoconf-swot/).  Of
  course, we are in the process of replacing this by Meson.  Meson
  maintenance is very active.  For now.

* The ossp-uuid library has been unmaintained for over ten years.  We
  support a variety of uuid libraries now, so it's gotten a bit
  complicated.

The two possible points are:

Projects like PostgreSQL have money and professional contributors.
Some projects that PostgreSQL relies on do not.  Just as we sometimes
ask users of PostgreSQL to contribute money or developer time,
projects like PostgreSQL should, arguably, also contribute money or
developer time to what it uses.  It's not straightforward to just pass
through donations (for legal reasons), but it's something to think
about in principle.

The second point is a bit harder, because you can't contribute if
there is no maintainer, that is, someone to receive the contributions.
Becoming a new maintainer is a larger commitment.  Would it make sense
for, say, a PostgreSQL company to hire or sponsor someone to become
the new IPC::Run maintainer or the new DocBook XSL maintainer (or
previously the new Autoconf maintainer)?  How would you organize that
and what would the economic model be?  Not clear.
