---
title: "How to submit a patch by email, 2023 edition"
comments: true
tags:
- git
- postgresql
---

In 2009, I wrote a blog post [_How to submit a patch by
email_](https://petereisentraut.blogspot.com/2009/09/how-to-submit-patch-by-email.html),
which became popular at the time and also ended up in the [PostgreSQL
wiki](https://wiki.postgresql.org/wiki/Submitting_a_Patch).  That
article was written pre-Git and
pre-[cfbot](http://cfbot.cputube.org/), so maybe it's time for a
refresher, as we head into the next PostgreSQL development cycle.

The short answer is: Use [`git
format-patch`](https://git-scm.com/docs/git-format-patch).  That takes
care of almost all of the conventions and details.  Looking at the
[upcoming commit fests](https://commitfest.postgresql.org/43/), it
appears that the vast majority of patch submissions already use that.
But I suspect that in some cases people produce the patches in some
other way and then rename them to look like what other people are
doing, without knowing about `git format-patch`?

Here is the basic workflow:

```
$ git checkout -b my-feature-branch
# hack hack hack
$ git commit ...
$ git format-patch master
0001-Add-my-feature.patch
```

And if you later update your patch and want to send in a new version,
you can do:

```
# hack hack hack
$ git commit --amend --reset
$ git format-patch -v2 master
v2-0001-Add-my-feature.patch
```

(You can also version your first patch as `-v1`.  Or you can try to be
optimistic and hope your patch won't require a second version. ;-) )

You can also split up your submission into multiple commits:

```
$ git checkout -b my-feature-branch
# hack hack hack
$ git add ...
$ git commit ...
$ git add ...
$ git commit ...
$ git format-patch master
0001-Some-refactoring.patch
0002-Add-my-feature.patch
```

Exactly how to split up a submission into commits sensibly is perhaps
the subject of another article, but in general it's something that is
encouraged and welcome.

Note the following features of what `git format-patch` produces:

- Patch files automatically get a descriptive name.

- Patch files get the correct file extension.

- Patch files are numbered so they sort easily.

- When using versions, files belonging to a version sort together.
  (The alternative manual naming like "my-feature-v2.patch" is
  therefore wrong.)

Morever, since `git format-patch` is based on _commits_, not working
tree state (like `git diff`), it requires you to write a commit
message, which is highly encouraged, even if you are not a committer.
Obviously, the accompanying email will normally explain the patch as
well, but as threads get longer, it is no longer easy to find that
information.  Having an up-to-date explanation in the patch itself is
vastly preferrable.  Also, some committer will eventually have to
write the commit message.  Getting that process started early makes
the final commit easier.

Also note that the output of `git format-patch` is designed to be fed
into [`git am`](https://git-scm.com/docs/git-am) to apply the patches.
I can easily apply a sequence of patches like this: `git am
v5-*.patch`.  Doing it any other way takes much longer and is much
more complicated.

`git format-patch` has a lot of options, and trying to understand them
all can be overwhelming.  For PostgreSQL work, you need almost none of
them.  Here are a few options can you play with:

- `-1`, `-2`, etc.: This specifies how many commits from the HEAD to
  make patches for.  In the invocation that I have shown, `git
  format-patch master`, it starts from where your development branch
  forked off the `master` branch.  This is usually the best way to do
  it.  But in some cases, if you have a complicated branch structure
  or made a mess, specifying it numerically is a good workaround.

- `--minimal`, `--patience`, and other diff algorithm options: This is
  optional, but in some cases choosing a different diff algorithm can
  make the patch look a bit nicer.

- `-Oorderfile`: This can change the order of the files in the patch.
  See [this blog
  post](https://til.cybertec-postgresql.com/post/2019-10-10-%22diff.orderFile:-order-your-git-diff-output-smart!%22/)
  for an example.  Personally, I wouldn't go quite as far as that
  article suggests, because then it will make it harder for a reviewer
  to find the files in the patch if they don't know the orderfile.
  The normal order that ends up being, doc, code, tests, is usually
  pretty sensible.  Maybe move `contrib` to the end if your patch has
  to touch it but it's not the primary focus of the patch.

- `--base`: This option records what commit your patch series was
  based on.  So someone who wants to apply the patch can use the same
  commit to apply it on, to avoid merge conflicts and guessing.  To
  invoke it, just do something like `git format-patch master --base
  master`.

I do want to retract from my previous article the point about
diffstats.  I have come to find them useful.  Leave them in, they
don't take up much space and don't hurt anything.

Now finally, here is the most important thing when sending a patch,
something that `git format-patch` cannot help you with.  Make sure
your email program sends the attachments with an appropriate content
type.  It should be `text/x-patch` or `text/x-diff` or
`text/something`, but *not* `application/octet-stream`.  The latter
makes it harder to look at the patch in the email client or in the
email [archives](https://www.postgresql.org/list/pgsql-hackers/) on
the web.  If I'm casually browing patches, if an attachment is sent as
`application/octet-stream`, I'm much less likely to look at it.  There
are plenty of other patches to look at that don't have that problem.

Summary:

* patches generated with `git format-patch` and applicable with `git am`
* sent using suitable email content type
