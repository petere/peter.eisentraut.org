---
layout: post
title: "Listing screen sessions on login"
date: 2015-02-16 20:00:00 -0500
comments: true
tags:
- screen
---

There is a lot of helpful information about `screen` out there, but I
haven't found anything about this.  I don't want to "forget" any
screen sessions, so I'd like to be notified when I log into a box and
there are screens running for me.  Obviously, there is `screen -ls`,
but it needs to be wrapped in a bit logic so that it doesn't annoy
when there is no `screen` running or even installed.

After perusing the `screen` man page a little, I came up with this for
`.bash_profile` or `.zprofile`:

```sh
if which screen >/dev/null; then
    screen -q -ls
    if [ $? -ge 10 ]; then
        screen -ls
    fi
fi
```

The trick is that `-q` in conjuction with `-ls` gives you exit codes
about the current status of `screen`.

Here is an example of how this looks in practice:

    ~$ ssh host
    Last login: Fri Feb 13 11:30:10 2015 from 192.0.2.15
    There is a screen on:
            31572.pts-0.foobar      (2015-02-15 13.03.21)   (Detached)
    1 Socket in /var/run/screen/S-peter.
    
    peter@host:~$ 
