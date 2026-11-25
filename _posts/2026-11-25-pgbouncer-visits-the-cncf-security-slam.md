---
title: "PgBouncer visits the CNCF Security Slam"
comments: true
tags:
- cncf
- openssf
- pgbouncer
- postgresql
---

Last month, [PgBouncer](https://www.pgbouncer.org/) participated in
the [Fall 2026 CNCF Security
Slam](https://securityslam.com/outcomes/fall-2026).  This is a report
of what we did, what we learned, and what we plan for the future.

## Introduction

First, let's introduce the participants.  PgBouncer is a connection
pooler for PostgreSQL.  The [CNCF](https://www.cncf.io/) is the Cloud
Native Computing Foundation, the organization that supports Kubernetes
and many other projects broadly related to that.  There is also the
[OpenSSF](https://openssf.org/), the Open Source Security Foundation,
which publishes many tools and guides to help open-source projects
improve and maintain their security practices.  Both the CNCF and the
OpenSSF are part of the [Linux
Foundation](https://www.linuxfoundation.org/), so they are kind of
sibling organizations.

The [Security Slam](https://securityslam.com/) is an event that the
CNCF has run, in varying shapes, for [some
years](https://securityslam.com/outcomes).  In its current shape, it
is a one-month virtual event in which participating projects can earn
"badges" for achieving specified tasks relating to improving (or
establishing) their security posture.  The tasks are generally
organized around achieving certain milestones based on guides
published by the OpenSSF, especially the [Open Source Project Security
Baseline](https://baseline.openssf.org/).  (The exact tasks vary from
event to event; see below for details.)  I had been following the
OpenSSF work for some time, and I had been making some progress on
applying some of their guides to my work, so I became interested in
this event.

In the past, the Security Slam was only for CNCF-affiliated projects.
I believe the original intent was to help those projects along on
their [graduation
ladder](https://contribute.cncf.io/projects/lifecycle/).  I had heard
about the Security Slam via the
[CloudNativePG](https://cloudnative-pg.io/) project, which
participated (to some
[fanfare](https://www.cncf.io/reports/slam26-spring-transparency-report/))
in the Spring 2026 edition.  But now the "Slam" is also open to
non-CNCF projects.  So I decided to give it a go with PgBouncer.

Why PgBouncer?  I'm one of the maintainers of PgBouncer, and to
participate in the Security Slam, you need to be a project maintainer
(or at least one of the participants needs to be, I think).  As we
will see, most of the initial tasks are documenting things, and as a
long-time maintainer of PgBouncer, a lot of that information was in my
head and needed to be written down anyway.  I think PgBouncer is also
a good proxy for introducing these OpenSSF practices into the
PostgreSQL ecosystem.  PgBouncer is relatively complex but not too
large, it presents interesting challenges but it's tractable.  It is
[hosted on GitHub](https://github.com/pgbouncer/pgbouncer/) with a
fairly standard setup and workflows, which helps with the available
tooling.  Also, it exists separately from PostgreSQL proper, so it
does not depend on, for example, getting any API changed upstream.
Obviously, the "final boss" would be to get PostgreSQL itself through
the Security Slam, or at least to get many of those practices adopted,
but we need to start small, and as we'll see it was difficult enough.

This Security Slam consisted of six badges, which are meant to be
tackled in succession.  I decided right at the beginning that it's
only realistic to achieve the first four.  The fifth badge is
basically, fix all remaining controls in the OpenSSF's [OSPS
Baseline](https://baseline.openssf.org/) checklist, which you might as
well interpret as, fix all remaining problems.  The way the Baseline
is organized is by "maturity level" of your project.  This is not
something you pick, this is just a fact about how your project is
used.  So an early-stage CNCF project might be at maturity level 1 and
have a relatively short list of controls to check off.  But PgBouncer
is at the highest maturity level 3, which is a very long list of
controls.  (In fact, PgBouncer would more or less satisfy the
requirements of level 1 now.)  This is by design of the Baseline:
Mature projects carry a lot of responsibility; there is no partial
credit. But that makes retrofitting a mature project into this set of
requirements a long and difficult project that wasn't realistic to
achieve inside a one-month sprint, I mean, slam.

And so the outcome was that we did earn [4 of 6
badges](https://securityslam.com/outcomes/fall-2026/pgbouncer).

Here is what we did:

(To be clear, most of the work for PgBouncer's participation in the
Security Slam was done by me, with the consensus of the PgBouncer
maintainer group.  Anything I write here about insights or future
plans are just my own ideas at the moment and will have to be
discussed and reviewed using the normal processes.)

## Badge 1: Cleaner

We added a [`security-insights.yml`
file](https://github.com/pgbouncer/pgbouncer/blob/master/security-insights.yml).
This is an [emerging
standard](https://github.com/ossf/security-insights) for pointing to
project documentation about security-related information.  For
example, this identifies the project's canonical repository, the
project maintainers, and links to various pieces of documentation,
such as vulnerability reporting information, support policy, release
management, and more.  It also documents which security tooling is in
place.  As a first step, we just linked to what we already had and
then filled in additional information for the subsequent badges.

What we learned: The PgBouncer website (pgbouncer.org) is part of the
software distribution pipeline, so its repository needs to be
similarly scrutinized and secured.  This was mostly okay, but it is
good to be aware of this as we evolve our practices.  The security
insights files are designed so that they can link multiple
repositories together if they are related to a single product.

We also realized (or at least re-realized) that we are running the
Clang static analyzer (scan-build) on GitHub Actions, but no one is
really looking at the results.

Follow-up actions:

* Double check that the web site repository is properly secured and stays that way.
* Develop a process for running the static analyzer more systematically.
* Fill in more of the fields in the security insights file.  This is
  the job in the next badge.

## Badge 2: Chronicler

The task here was to complete all the applicable documentation tasks
from the OSPS Baseline and link them from the security insights file.

Here is what we added:

* A [`CONTRIBUTING.md`
  file](https://github.com/pgbouncer/pgbouncer/blob/master/CONTRIBUTING.md).
  This is of course established practice by now, but we didn't have
  one yet.  I suppose for the most part we assumed that interested
  people know how to contribute to an open-source project on GitHub.
  But it's also worth writing that down just a little bit.  But the
  guidance actually went much deeper, and so we documented some
  requirements for acceptable contributions, some developer tooling
  such as for formatting source code that was previously not
  explicitly documented, and some general tips for dealing with
  PgBouncer code.

* We also added some documentation on [dependency
  management](https://github.com/pgbouncer/pgbouncer/blob/master/CONTRIBUTING.md#dependencies).
  This is where it got interesting.  A lot of the dependency
  management content in OpenSSF guides is (probably) conceived in the
  context of tools like Go or Rust that manage their own dependencies.
  For a C project like PgBouncer, how does this matter?  We don't
  distribute any binaries, we don't enforce any dependency versions,
  that is done by downstream packagers.  But we should still say that!
  Also, we have some dependencies.  There is vendored code copied from
  PostgreSQL and some other sources.  And we distribute a Windows
  binary as part of the release assets, which is probably a bad idea
  the more you think about it.  It's also worth writing down how you
  decide what external projects you want to accept as dependencies and
  how you decide what minimal version to require.  This is the kind of
  thing that usually only exists in lore, but writing it down is
  useful.

* A [`SECURITY.md`
  file](https://github.com/pgbouncer/pgbouncer/blob/master/SECURITY.md).
  Again, this is established practice.  But I see many projects just
  writing down how to report security issues and not much more.  The
  guidance from the Security Slam went much deeper.  Also, the
  PgBouncer project was at the same time, independently, applying to
  be integrated into Anthropic's [OSS
  Scanner](https://red.anthropic.com/oss-scanner/) program, which also
  required writing down some of the same information, so this turned
  out to be a good synergy.  Besides basic security contact
  information and a threat classification model, we also documented
  where security information is published, and what the versioning and
  support policy is.  Again, this has existed in lore and actual
  practice, but it was not written down.

* Who runs this project and how are decisions made?  Again, none of
  this is surprising if you're familiar with open-source projects and
  the PostgreSQL ecosystem, but how are newly arriving contributors or
  users supposed to discover this?  Now it's
  [documented](https://github.com/pgbouncer/pgbouncer/wiki/Governance).

* We also documented how the findings of static analysis are currently
  handled.  As mentioned above, it could be worth improving this, but
  again it's also useful to document the status quo even if it's not
  great, to manage expectations.

What we learned: Writing things down helps both users and maintainers.
Users get the actual information, and expectations are managed.
Maintainers don't have to remember everything, uncertainties or
information mismatches between multiple maintainers are clarified, and
again expectations are managed.

Follow-up actions:

* There is still more to document and more details to fill in.
* The Windows binaries should probably be removed, but we should make
  sure that users have an alternative.

## Badge 3: Inspector

This badge asked to write a security self assessment for the project.
The result is
[here](https://github.com/pgbouncer/pgbouncer/blob/ac3bb6d748cefc9470c2c66e061549a59a072ce3/doc/security-self-assessment.md).

I was not familiar with this, so I needed to do some reading and
studying.  Like, we just wrote the `SECURITY.md` file, how is this
supposed to be different?  In the end, I arrived at a few different
ways of thinking about this: One, the self assessment maps the threat
model to the code.  How is what you are claiming in your model
implemented?  Two, `SECURITY.md` and all the other documentation we
just wrote describe what we claim the policy to be, but in the
security assessment we evaluate how well it is going.  Three, this
allows you to identify gaps in your security posture, both code and
processes, and write a kind of roadmap.  Another difference is that
the `SECURITY.md` file and the other project documentation files
should be kept up to date all the time, but the self assessment is a
report about now, and then it gets updated from time to time (it says
yearly, we'll see), and then this gives opportunity for reflection and
planning.

At least that's how I ended up thinking about it, and the Security
Slam organizers accepted it, and I think the resulting document is
actually quite useful.  I suspect, in many cases this will be written
by newly created projects before they are widely published, in which
case it is probably more of a moment to reflect on, have we thought
all of this through, but for mature projects it is a bit of a
different task.

The Security Slam organizers [provided LLM
skills](https://github.com/security-slam/skills) to help with all
these tasks, and I made heavy use of that for this badge.  This was,
in a way, uniquely useful here because these kinds of tools can do a
good job mapping between code and human language.  But it did need a
lot of back and forth before I settled on a result document.

## Badge 4: Mechanizer

This badge asked to automate the OSPS Baseline scanning.  This was
actually pretty easy in our case, as we just installed the [provided
GitHub
Action](https://github.com/pgbouncer/pgbouncer/actions/workflows/osps-baseline.yml).
We actually did this before badge 2 and 3, as it was then also nice to
see how some controls flipped from red to green as you progressed.
(Since we had already decided beforehand not to attempt the next
badges, we didn't bother trying to set up uploading to
[grc.store](https://grc.store/), which was another possibility for
completing this badge.)

## What's next?

The next badge after this would have been the Defender badge, which
was as mentioned to fix all remaining Baseline controls.  (For
completeness, the sixth badge was "CRA Readiness", which I didn't even
think about, since we weren't going to do the Defender badge, and also
we don't have an open-source software steward.)  This is a long list
to work through.  Some of these might be technicalities, some might
not apply in a straightforward way to a C project, some I might not
have understood yet.  The main tasks appear to be:

* Signed releases.
* Apply static analysis and dependency vulnerability scanning on every
  change.
* Some fine-tuning on the CI setup.

Work on that is proceeding.  And of course we ought to work through
some of the issues mentioned in the security self assessment as well.
There are, incidentally, a number of opportunities there for new
contributors to help out!

And maybe we'll throw our hat in the ring for a future Security Slam
if they'll have us back.
