---
title: "How collation works"
comments: true
tags:
- postgresql
---

In this blog post, and probably one or more following ones, I want to
discuss how collations in PostgreSQL work internally.  See also this
previous [post]({% post_url 2022-09-26-icu-features-in-postgresql-15
%}) about the work we have done for collations in PostgreSQL 15.  And
there is even more coming together in PostgreSQL 16 right now, which
we will talk about in the future.

## Sorting

Sorting is an important functionality in a database system.  Sorting
happens internally, for example in B-tree indexes and during merge
joins, and externally when the user requests it.

There are two major aspects to sorting.  First, the sort algorithm,
how you put the values into sorted order in an efficient way,
considering time and space requirements.  This is a classical computer
science problem.  I'm not going to talk about that here.  Second, how
to decide what the sort order should be.  For many kinds of data this
is obvious, for example for numbers and date/time values.  In the
context of character strings, this process is called collation and is
a bit more complicated.

Of course, there is some kind of base order of A, B, C, ... that is
mostly(?) agreed upon.  But there are a variety of well-known and
lesser-known complications: how to handle case differences, accents,
punctuation, whitespace, variations in different languages, variations
within the same language, data in multiple languages, and more.

Sorting text in a way that satisfies the end user is important.  Most
of what the end user sees is text.  Numbers like IDs are mostly used
internally, but the user wants to see a list of names or products or
streets or cities, and usually they want to see them sorted.

(If you think about, the reason why end users want sorted output is
the same reason why the database uses sorted values internally: To be
able to find things faster.  If you have a list of sorted names, if
you want to find a specific name, you do an implicit binary search on
the fly.  Similarly, if you want to compare two lists, if they are
sorted, you can do a sort of ad-hoc merge join.  It's all the same
idea.)

## Standards

There are standards for this, both industry standards and standards
from governments and language authorities.  Nowadays, this all centers
around Unicode.  Other character encodings are still in use, but how
the collation works is all defined in terms of Unicode and then
adapted to those other encodings.  [_The Unicode
Standard_](https://unicode.org/standard/standard.html) itself is
mainly concerned with what characters exist and what their properties
are.  A separate document, [_Unicode Technical Standard #10: Unicode
Collation Algorithm_](https://unicode.org/reports/tr10/) (UTS #10,
UCA) specifies how collation is supposed to work.  That document is
technical but readable, so it's a good resource to learn more.

There is a parallel set of ISO/IEC standards: ISO/IEC 10646
"Information technology — Universal Coded Character Set (UCS)" and
ISO/IEC 14651 "Information technology — International string ordering
and comparison — Method for comparing character strings and
description of the common template tailorable ordering".  These are
effectively the same as the Unicode standard and UTS #10,
respectively, but they exist in the ISO/IEC realm so that it is easier
to create other standards in that realm based on them (such as the SQL
standard, ISO/IEC 9075).

UCA also defines a default sort order.  This is the Default Unicode
Collation Element Table (DUCET).  This is, under Unicode, the default
sort order, barring any customization.  If you want to create a
different sort order, for example for a particular language, you would
normally take the DUCET and apply a few customizations to it.  (There
is a special customization language for that.)  But the default order
actually works for many languages out of the box and is a good choice
for text in multiple languages or if no clear preference is known.

One final acronym: [CLDR](https://cldr.unicode.org/) is the Common
Locale Data Repository, where many of these customizations are
maintained (basically, for each language and variant).  This data is
nowadays used by many libraries that provide collation and other
locale services, such as [ICU](https://icu.unicode.org/) (ok, another
acronym there).

Anyway, that's where all of this comes from nowadays.  Now let's look
at how it actually functions.

## Examples

Say you want to compare the strings `abc` and `def`.  Traditionally,
you might look at the byte values of the letters and compare those
using a memory comparison.  In the UCA world, each letter is instead
assigned not one but three values, called weights.  Let's look
directly at the [DUCET data
file](https://www.unicode.org/Public/UCA/latest/allkeys.txt):

	0061  ; [.2075.0020.0002] # LATIN SMALL LETTER A
	0062  ; [.208F.0020.0002] # LATIN SMALL LETTER B
	0063  ; [.20A9.0020.0002] # LATIN SMALL LETTER C
	0064  ; [.20BF.0020.0002] # LATIN SMALL LETTER D
	0065  ; [.20DB.0020.0002] # LATIN SMALL LETTER E
	0066  ; [.2116.0020.0002] # LATIN SMALL LETTER F

The numbers on the very left are the Unicode code points (in
hexadecimal).  The three values in brackets are the weights.  (The
various punctuations are mainly there to make parsing this file
easier.)  A set of weights like this is called a collation element.
In this case, the secondary and tertiary weights are all the same,
because they are all small Latin letters.  We will see some other
cases below.

(Note: The actual numbers might change between Unicode versions.  Only
their relative values matter, after all.)

To compute the _sort keys_ from that, you concatenate first the
primary weights from each character in order, then the secondary
weights, then the tertiary weights, separated by zero words.  So here
we'd have

	'abc' => 2075 208F 20A9 0000 0020 0020 0020 0000 0002 0002 0002
	'def' => 20BF 20DB 2116 0000 0020 0020 0020 0000 0002 0002 0002

This can then be sorted using a normal byte comparison.

In practice, an implementation can optimize this a bit.  For example,
the sort keys could be computed incrementally on the fly, or perhaps a
compressed representation could be used.  (UTS #10 gives [some
hints](https://unicode.org/reports/tr10/#Implementation_Notes).)
Also, in the standard C API, you can't have zero bytes in the middle
of a string, so a different representation would have to be used.
(The sort key is what is returned from `strxfrm()`.)  But the
principle is the same.

How does this handle strings of different lengths?  Let's compare
`abc` and `abcd`:

	'abc'  => 2075 208F 20A9 0000 0020 0020 0020 0000 0002 0002 0002
	'abcd' => 2075 208F 20A9 20BF 0000 0020 0020 0020 0020 0000 0002 0002 0002 0002

Because of the zero "divider", this works out that the shorter string
compares as less, which is what we want.

Now let's look at something with accents and different cases.  Let's
compare `äBc` and `déF`.  We look up the weights of the characters:

	00E4  ; [.2075.0020.0002][.0000.002B.0002] # LATIN SMALL LETTER A WITH DIAERESIS
	0042  ; [.208F.0020.0008] # LATIN CAPITAL LETTER B
	0063  ; [.20A9.0020.0002] # LATIN SMALL LETTER C
	0064  ; [.20BF.0020.0002] # LATIN SMALL LETTER D
	00E9  ; [.20DB.0020.0002][.0000.0024.0002] # LATIN SMALL LETTER E WITH ACUTE
	0046  ; [.2116.0020.0008] # LATIN CAPITAL LETTER F

There is more stuff going on here.  First, some characters map to more
than one collation element.  Also, where above the different collation
elements only differed in their primary weight, here you can see
differences in the secondary and tertiary weights.  If you analyze it
more carefully, you will determine that the secondary weight has
something to do with accents and the tertiary weight has something to
do with case.

Let's create the sort keys as before, by concatenating the weights in
turn, but skipping zero weights:

	'äBc' => 2075 208F 20A9 0000 0020 002B 0020 0020 0000 0002 0008 0002
	'déF' => 20BF 20DB 2116 0000 0020 0020 0024 0020 0000 0002 0002 0008

If you compare this, it's actually effectively the same comparison as
comparing plain `abc` with `def` above, since the comparison is
already resolved before we get to the secondary weights.  But you can
see that if the primary weights were equal (say comparing `äBc` with
`abC`), then it would first consider the accents, and then, if
required, the case.

The accents have some presumably fairly arbitrary ordering (diaeresis
is 002B, acute is 0024).  The cases are ordered as lower (0002) before
upper (0008) by default.

## Customizations

Various customizations can be applied in this system.  For example, if
you want to sort upper case letters before lower-case letters, you can
use the locale specification `und-u-kf-upper`, which would internally
swap the values of the tertiary weights.  (There is a bit more detail,
because there are also "case" weights other than 0002 and 0008, but in
any case it adjusts the tertiary values in some algorithmic way.)  If
you want to ignore case altogether, you can use the locale
specification `und-u-ks-level2`, which basically says, to ignore
weights beyond the second level.  If you want to ignore accents, the
specification would be `und-u-ks-level1-kc-true`, which is a bit more
tricky, because it says to ignore all weights beyond the first one
(`-ks-level1`) but then move the case level to the second one
(`-kc-true`).  All of these can be handled easily within this
framework.

My personal preferred reference for this is the PostgreSQL
documentation (<https://www.postgresql.org/docs/15/collation.html>).
There is more elaborate documentation in the underlying libraries and
standards, but I think those are quite difficult to navigate.
Therefore, we have tried to include some of that information in the
PostgreSQL documentation, so it's easier for users to get started.

## What's next

Now, where a lot of users get confused is how punctuation, spaces, and
things like that are handled.  I'll discuss that in a future article.
