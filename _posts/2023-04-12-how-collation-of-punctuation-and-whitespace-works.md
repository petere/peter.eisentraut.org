---
title: "How collation of punctuation and whitespace works"
comments: true
tags:
- postgresql
---

In a [previous article]({% post_url 2023-03-14-how-collation-works
%}), I described how collation works internally in PostgreSQL in
general.  In that article, we left open how collation of punctuation
and whitespace works.  This is where a lot of users get confused.
Let's look at that now.

First, let's think about what we might like to happen.  Maybe we want
to treat punctuation and whitespace characters just like other
characters.  They sort in some relative location, and that's it.  Or
maybe we want to mostly ignore these characters for sorting.  Both of
these are valid choices, and where people get upset is mainly when
they expected one and get the other.  In fact, Unicode allows both of
these choices (and more!), and the implementation has to pick one or
make users select one.  (To keep it simple, I'll just write "Unicode"
in this article to mean one of the various standards that affect
collation of Unicode characters.  See the previous article for
details.)

Before we get into that, let's look at the collation data.  Recall how
"normal" collation elements look:

	0061  ; [.2075.0020.0002] # LATIN SMALL LETTER A
	0062  ; [.208F.0020.0002] # LATIN SMALL LETTER B
	0063  ; [.20A9.0020.0002] # LATIN SMALL LETTER C

Now let's look at some whitespace and punctuation characers.  I'm
using the normal space and the ASCII hyphen (called "hyphen-minus" in
Unicode) here as representatives:

	0020  ; [*0209.0020.0002] # SPACE
	002D  ; [*020D.0020.0002] # HYPHEN-MINUS

Note the asterisk (`*`).  This is a marker that these elements are
special.  They are called _variable collation elements_.  This means
you can decide what you want to do with them.

(I write "punctuation and whitespace" in this article, because those
are the kinds of characters that most often cause questions, and
because they are most readily understandable by someone used to a
Latin alphabet.  There are several thousand variable collation
elements in Unicode, including special characters in alphabets other
than the Latin one, various mathematical symbols, other symbols, as
well as emoji.  These all behave the same for this purpose.)

There are four options defined in Unicode for handling variable
collation elements:

* non-ignorable
* blanked
* shifted
* shift-trimmed

Let's look at how each of these would work for sorting the following
example:

	'death', 'deluge', 'de luge'

First, here are all the weights for the characters involved:

	0020  ; [*0209.0020.0002] # SPACE
	0061  ; [.2075.0020.0002] # LATIN SMALL LETTER A
	0064  ; [.20BF.0020.0002] # LATIN SMALL LETTER D
	0065  ; [.20DB.0020.0002] # LATIN SMALL LETTER E
	0067  ; [.2125.0020.0002] # LATIN SMALL LETTER G
	0068  ; [.214C.0020.0002] # LATIN SMALL LETTER H
	006C  ; [.21B0.0020.0002] # LATIN SMALL LETTER L
	0074  ; [.22DF.0020.0002] # LATIN SMALL LETTER T
	0075  ; [.2301.0020.0002] # LATIN SMALL LETTER U

If the option is **non-ignorable**, then the variable collation
elements are treated just like a normal collation element.  So the
resulting sort keys and order would be:

	'de luge' => 20BF 20DB 0209 21B0 2301 2125 20DB 0000 0020 0020 0020 0020
	             0020 0020 0020 0000 0002 0002 0002 0002 0002 0002 0002
	'death'   => 20BF 20DB 2075 22DF 214C 0000 0020 0020 0020 0020 0020 0000
	             0002 0002 0002 0002 0002
	'deluge'  => 20BF 20DB 21B0 2301 2125 20DB 0000 0020 0020 0020 0020 0020
	             0020 0000 0002 0002 0002 0002 0002 0002

So the space character sorts pretty much like a letter here.  In this
case, the space sorts before the letter "a", which is how you get this
particular order, but it is not necessarily the case that variable
collation elements have weights lower than other collation elements.

If the option is **blanked**, the variable collation elements are
ignored altogether.  In our example, this would be the result:

	'death'   => 20BF 20DB 2075 22DF 214C 0000 0020 0020 0020 0020 0020 0000
	             0002 0002 0002 0002 0002
	'deluge'  => 20BF 20DB 21B0 2301 2125 20DB 0000 0020 0020 0020 0020 0020
	             0020 0000 0002 0002 0002 0002 0002 0002
	'de luge' => 20BF 20DB 21B0 2301 2125 20DB 0000 0020 0020 0020 0020 0020
	             0020 0000 0002 0002 0002 0002 0002 0002

Here, the last two strings compare as equal.  If the task is to sort
them (as opposed to compare them), it would then depend on the
implementation what the actual order would be.

If the option is **shifted**, a fourth weight is effectively added.
For the variable collation elements, the 1st-level weight is "shifted"
to the 4th level.  (The 2nd- and 3rd-level weights are dropped.)  For
the normal collation elements, the fourth weight is set to FFFF (that
is, higher than anything else).  So in our case, we would have these
effective weights:

	0020  ; [.0000.0000.0000.0209] # SPACE
	0061  ; [.2075.0020.0002.FFFF] # LATIN SMALL LETTER A
	0064  ; [.20BF.0020.0002.FFFF] # LATIN SMALL LETTER D
	0065  ; [.20DB.0020.0002.FFFF] # LATIN SMALL LETTER E
	0067  ; [.2125.0020.0002.FFFF] # LATIN SMALL LETTER G
	0068  ; [.214C.0020.0002.FFFF] # LATIN SMALL LETTER H
	006C  ; [.21B0.0020.0002.FFFF] # LATIN SMALL LETTER L
	0074  ; [.22DF.0020.0002.FFFF] # LATIN SMALL LETTER T
	0075  ; [.2301.0020.0002.FFFF] # LATIN SMALL LETTER U

And the collation result is:

	'death'   => 20BF 20DB 2075 22DF 214C 0000 0020 0020 0020 0020 0020 0000
	             0002 0002 0002 0002 0002 0000 FFFF FFFF FFFF FFFF FFFF
	'de luge' => 20BF 20DB 21B0 2301 2125 20DB 0000 0020 0020 0020 0020 0020
	             0020 0000 0002 0002 0002 0002 0002 0002 0000 FFFF FFFF 0209
	             FFFF FFFF FFFF FFFF
	'deluge'  => 20BF 20DB 21B0 2301 2125 20DB 0000 0020 0020 0020 0020 0020
	             0020 0000 0002 0002 0002 0002 0002 0002 0000 FFFF FFFF FFFF
	             FFFF FFFF FFFF

As you can see here, unlike the non-ignorable case, this keeps strings
that are only different by some whitespace closer together.

Finally, the option **shift-trimmed** is like shifted, but any
trailing sequences of FFFF are removed ("trimmed").

This is the collation result:

	'death'   => 20BF 20DB 2075 22DF 214C 0000 0020 0020 0020 0020 0020 0000
	             0002 0002 0002 0002 0002 0000
	'deluge'  => 20BF 20DB 21B0 2301 2125 20DB 0000 0020 0020 0020 0020 0020
	             0020 0000 0002 0002 0002 0002 0002 0002 0000
	'de luge' => 20BF 20DB 21B0 2301 2125 20DB 0000 0020 0020 0020 0020 0020
	             0020 0000 0002 0002 0002 0002 0002 0002 0000 FFFF FFFF 0209

Here is a summary how these four options behave:

| non-ignorable | de luge, death, deluge |
| blanked | death, deluge == de luge |
| shifted | death, de luge, deluge |
| shift-trimmed | death, deluge, de luge |

So, which one is better?  I suppose there are different opinions and
different use cases, which is why these options have been developed.

Then, how do you select the one you want?  This depends on the
library.

If you use the C library, and I'm thinking specifically of the GNU C
library, but this applies to others as well, there isn't a way to
choose, but the library picks one behavior for you.  For glibc
versions up to 2.27, the behavior was like shift-trimmed, from version
2.28 on, the behavior is like shifted.  (This change was the main
cause of the PostgreSQL [locale
apocalypse](https://wiki.postgresql.org/wiki/Locale_data_changes).)
Note that the shift-trimmed behavior in Unicode was really only meant
for POSIX compatibility, so using shifted going forward makes sense.

If you use the ICU library, there is a way to attach various options
to locale specifications, and the variable element behavior is one of
those options.  The default in ICU is non-ignorable.  (So by default
you get different behavior between glibc and ICU.)  To pick the
shifted behavior, use a locale specification like one of these:

	en@colAlternate=shifted
	en-u-ka-shifted

The default behavior can be selected explicitly like these:

	en@colAlternate=noignore
	en-u-ka-noignore

For example, to initialize a new PostgreSQL instance using ICU and the
shifted behavior:

	$ initdb -D data --locale-provider=icu --icu-locale=en-u-ka-shifted

To create a collation with the shifted behavior:

	CREATE COLLATION c1 (provider = icu, locale = 'en-u-ka-shifted');

(Obviously, you don't have to use "en" as the base locale.)

Note that ICU does not implement the other options shift-trimmed and
blanked.

So this is the whole mystery of collation of punctuation and
whitespace and the like.

Here are some links with additional information:

- <http://www.unicode.org/reports/tr10/#Variable_Weighting>: the
  relevant section of the Unicode Collation Algorithm specification
- <https://unicode-org.github.io/icu/userguide/collation/customization/ignorepunct.html>:
  ICU documentation on this matter (This one lists a fifth possible
  behavior "variable-after", but I don't know where that came from,
  and it's not actually implemented in ICU.)
- <https://www.postgresql.org/docs/15/collation.html#COLLATION-MANAGING>:
  PostgreSQL documentation about creating collations
