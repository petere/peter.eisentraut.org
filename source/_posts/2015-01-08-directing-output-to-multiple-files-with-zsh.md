---
layout: post
title: "Directing output to multiple files with zsh"
date: 2015-01-08 20:00:00 -0500
comments: true
categories:
- zsh
- planet debian
---

Normally, this doesn't work as one might naively expect:

    program > firstfile > secondfile

The second redirection will override the first one.  You'd have to use
an external tool to make this work, maybe something like:

    program | tee firstfile secondfile

But with zsh, this type of thing actually works.  It will duplicate
the output and write it to multiple files.

This feature also works with a combination of redirections and
pipes.  For example

    ls > foo | grep bar

will write the complete directory listing into file `foo` *and* print
out files matching `bar` to the terminal.

That's great, but this feature pops up in unexpected places.

I have a shell function that checks whether a given command produces
any output on stderr:

    ! myprog "$arg" 2>&1 >/dev/null | grep .

The effect of this is:

- If no stderr is produced, the exit code is 0.
- If stderr is produced, the exit code is 1 and the stderr is shown.

(Note the ordering of `2>&1 >/dev/null` to redirect stderr to stdout
and silence the original stdout, as opposed to the more common
incantation of `>/dev/null 2>&1`, which silences both stderr and
stdout.)

The reason for this is that `myprog` has a bug that causes it to print
errors but not produce a proper exit status in some cases.

Now how will my little shell function snippet behave under zsh?  Well,
it's quite confusing at first, but the following happens.  If there is
stderr output, then only stderr is printed.  If there is no stderr
output, then stdout is passed through instead.  But that's not what I
wanted.

This can be reproduced simply:

    ls --bogus 2>&1 >/dev/null | grep .

prints an error message, as expected, but

    ls 2>&1 >/dev/null | grep .

prints a directory listing.  That's because zsh redirects stdout to
*both* `/dev/null` and the pipe, which makes the redirection to
`/dev/null` pointless.

Note that in bash, the second command prints nothing.

This behavior can be changed by turning off the `MULTIOS` option (see
`zshmisc` man page), and my first instinct was to do that, but options
are not lexically scoped (I think), so this would break again if the
option was somehow changed somewhere else.  Also, I think I kind of
like that option for interactive use.

My workaround is to use a subshell:

    ! ( myprog "$arg" 2>&1 >/dev/null ) | grep .

The long-term fix will probably be to write an external shell script
in bash or plain POSIX shell.
