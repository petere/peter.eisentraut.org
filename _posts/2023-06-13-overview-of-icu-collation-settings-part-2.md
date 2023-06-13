---
title: "Overview of ICU collation settings, part 2"
comments: true
tags:
- icu
- postgresql
---

In a [recent article]({% post_url
2023-05-16-overview-of-icu-collation-settings %}), I covered the
parametric ICU collation customization settings.  In today's article,
I will describe the other major collation customization option: the
alternative collation types selected with the `co` key in the locale
identifier.

The best way to find out which types are available and what they do is
to look into the source code, which for ICU is the CLDR project.
Let's start with the [definition of the keys in
CLDR](https://github.com/unicode-org/cldr/blob/release-43/common/bcp47/collation.xml).
(In this article, all the URLs are for a specific CLDR release, which
is the latest one as I write this, because, as we will see below,
these things change over time.)

```xml
<key name="co" description="Collation type key" alias="collation">
    <type name="big5han" description="Pinyin ordering for Latin, big5 charset ordering for CJK characters (used in Chinese)"/>
    <type name="compat" description="A previous version of the ordering, for compatibility" since="26"/>
    <type name="dict" description="Dictionary style ordering (such as in Sinhala)" alias="dictionary"/>
    <type name="direct" description="Binary code point order (used in Hindi)" deprecated="true"/>
    <type name="ducet" description="The default Unicode collation element table order" since="2.0.1"/>
    <type name="emoji" description="Recommended ordering for emoji characters" since="27"/>
    <type name="eor" description="European ordering rules" since="24"/>
    <type name="gb2312" description="Pinyin ordering for Latin, gb2312han charset ordering for CJK characters (used in Chinese)" alias="gb2312han"/>
    <type name="phonebk" description="Phonebook style ordering (such as in German)" alias="phonebook"/>
    <type name="phonetic" description="Phonetic ordering (sorting based on pronunciation)"/>
    <type name="pinyin" description="Pinyin ordering for Latin and for CJK characters (used in Chinese)"/>
    <type name="reformed" description="Reformed ordering (such as in Swedish)"/>
    <type name="search" description="Special collation type for string search" since="1.9"/>
    <type name="searchjl" description="Special collation type for Korean initial consonant search" since="2.0.1"/>
    <type name="standard" description="Default ordering for each language"/>
    <type name="stroke" description="Pinyin ordering for Latin, stroke order for CJK characters (used in Chinese)"/>
    <type name="trad" description="Traditional style ordering (such as in Spanish)" alias="traditional"/>
    <type name="unihan" description="Pinyin ordering for Latin, Unihan radical-stroke ordering for CJK characters (used in Chinese)"/>
    <type name="zhuyin" description="Pinyin ordering for Latin, zhuyin order for Bopomofo and CJK characters (used in Chinese)" since="22"/>
</key>
```

Also of interest is the section that defines this in the relevant
standard UTS #35:
<http://unicode.org/reports/tr35/#UnicodeCollationIdentifier>

Just as a reminder, to use these options in a locale string that you
could pass to PostgreSQL (or another ICU application), the syntax
would be something like `de-u-co-phonebk` (new) or
`de@collation=phonebook` (old).

Now let's work through what these options do.  I give some examples
below, but many of these apply to characters that I am not really
familiar with, so I will refrain from giving examples there.

## big5han

Description: "Pinyin ordering for Latin, big5 charset ordering for CJK characters (used in Chinese)"

This collation type appears only in the [`zh` (Chinese)
collation](https://github.com/unicode-org/cldr/blob/release-43/common/collation/zh.xml#L10039).
Pinyin is a romanization system for Chinese characters.  Big5 is a
pre-Unicode character encoding used for Chinese.  So this is a
collation provided for compatibility with a particular pre-Unicode
convention.

See also [gb2312](#gb2312) for a similar idea.

## compat

Description: "A previous version of the ordering, for compatibility"

This collation type appears only in the [`ar` (Arabic)
collation](https://github.com/unicode-org/cldr/blob/release-43/common/collation/ar.xml#L14).

This is self-explanatory: The standard collation was tweaked and the
previous version is available as the "compat" type.

## dict

Description: "Dictionary style ordering (such as in Sinhala)"

This collation type appears only in the [`si` (Sinhala)
collation](https://github.com/unicode-org/cldr/blob/release-43/common/collation/si.xml#L22).
It makes some minor modifications compared to the standard collation
of Sinhala.

## direct

Description: "Binary code point order (used in Hindi)" (deprecated)

This collation type previously appeared in the `hi` (Hindi) collation,
but it was removed in 2012.

(PostgreSQL note: To get binary code point order, you can use the `C`
or `ucs_basic` collations.)

## ducet

Description: "The default Unicode collation element table order"

This collation type does not currently exist in any collation in CLDR.
DUCET is the actual Unicode standard while CLDR is the set of data
files that implementatons such as ICU actually use.  CLDR is slightly
modified ("tailored") from DUCET.  The intention of the `ducet`
collation type was to allow users to select an untailored pure
standard collation.  This existed briefly in CLDR in 2012 but was
quickly found to not work fully and be hard to maintain.

## emoji

Description: "Recommended ordering for emoji characters"

This collation type appears in the [root
collation](https://github.com/unicode-org/cldr/blob/release-43/common/collation/root.xml#L949).

There is a separate standard
[UTS&nbsp;#51](https://unicode.org/reports/tr51/#Sorting) for sorting
emoji characters, which this collation type implements.  This would be
suitable, for example, for presenting emoji characters in an input
selector.

Example:

```sql
select chr(x) from generate_series(x'1F634'::int, x'1F644'::int) as _(x)
    order by chr(x);
 chr
-----
 😴
 😵
 😶
 😷
 😸
 😹
 😺
 😻
 😼
 😽
 😾
 😿
 🙀
 🙁
 🙂
 🙃
 🙄

create collation c1 (provider = icu, locale = 'und-u-co-emoji');
select chr(x) from generate_series(x'1F634'::int, x'1F644'::int) as _(x)
    order by chr(x) collate c1;
 chr
-----
 🙂
 🙃
 😶
 🙄
 😴
 😷
 😵
 🙁
 😺
 😸
 😹
 😻
 😼
 😽
 🙀
 😿
 😾
```

You can see here that the default order puts the emoji characters in a
pretty arbitrary order.  The emoji sort puts them in groups (smiley
faces, cats) and also has a consistent order within the groups (happy,
neutral, sad).  See UTS #51 for details.

## eor

Description: "European ordering rules"

This collation type appears in the [root
collation](https://github.com/unicode-org/cldr/blob/release-43/common/collation/root.xml#L146),
and there is a "national delta" in the [`de` (German)
collation](https://github.com/unicode-org/cldr/blob/release-43/common/collation/de.xml#L30).

[European ordering
rules](https://en.wikipedia.org/wiki/European_ordering_rules) is a
standard (EN 13710) for sorting Latin, Greek, Cyrillic, Georgian, and
Armenian characters (that is, characters used by languages used in
Europe).  Which, you know, UCA does as well?  Looking at the history
of this, it appears this was worked on before the equivalent Unicode
standards were fully accepted, and I suspect this is mostly obsolete
now.

## gb2312

Description: "Pinyin ordering for Latin, gb2312han charset ordering for CJK characters (used in Chinese)"

This collation type appears only in the [`zh`
(Chinese)](https://github.com/unicode-org/cldr/blob/release-43/common/collation/zh.xml#L3897)
collation.  Pinyin is a romanization system for Chinese characters.
GB 2312 is a pre-Unicode character encoding used for Chinese (also
known as EUC-CN).  So this is a collation provided for compatibility
with a particular pre-Unicode convention.

See also [big5han](#big5han) for a similar idea.

## phonebk

Description: "Phonebook style ordering (such as in German)"

This collation type appears only in the
[`de`&nbsp;(German)](https://github.com/unicode-org/cldr/blob/release-43/common/collation/de.xml#L23)
and [`de_AT`&nbsp;(German in
Austria)](https://github.com/unicode-org/cldr/blob/release-43/common/collation/de_AT.xml#L16)
collations.

The German standard DIN 5007 specifies the sorting of character
strings.  It contains two parts: One general part, and one for the
sorting of lists of names.  The first part is actually the same as
the Unicode root collation, the second part is what is often called
the phonebook sorting, but it really applies to any list of person
names.

In CLDR, for the `de` collation, this collation type adds the
following rules:

```
&AE<<ä<<<Ä
&OE<<ö<<<Ö
&UE<<ü<<<Ü
```

This says that the letter `ä` sorts after `AE` with a secondary
difference, and `Ä` follows with a tertiary difference, and so on for
the other vowels.

For `de_AT`, this collation type adds the following rules instead:

```
&a<ä<<<Ä
&o<ö<<<Ö
&u<ü<<<Ü
&ss<ß<<<ẞ
```

This says that the letter `ä` sorts as a separate letter (primary
difference) after `a`, and so on.

Examples:

```sql
create collation german (provider = icu, locale = 'de');
create collation german_phonebook (provider = icu,
                                   locale = 'de-u-co-phonebk');
create collation austrian_phonebook (provider = icu,
                                     locale = 'de-AT-u-co-phonebk');

select *
    from (values ('Göbel'), ('Goethe'), ('Goldmann'), ('Göthe'), ('Götz')) _(x)
    order by x collate german;
     x
-----------
 Göbel
 Goethe
 Goldmann
 Göthe
 Götz
```

(This is the same as the root collation.)

```sql
select *
    from (values ('Göbel'), ('Goethe'), ('Goldmann'), ('Göthe'), ('Götz')) _(x)
    order by x collate german_phonebook;
     x
-----------
 Göbel
 Goethe
 Göthe
 Götz
 Goldmann

select *
    from (values ('Göbel'), ('Goethe'), ('Goldmann'), ('Göthe'), ('Götz')) _(x)
    order by x collate austrian_phonebook;
     x
-----------
 Goethe
 Goldmann
 Göbel
 Göthe
 Götz
```

See also
<https://de.wikipedia.org/wiki/Alphabetische_Sortierung#Deutsche_Sprache>
for more details on various variants of sorting in German.

## phonetic

Description: "Phonetic ordering (sorting based on pronunciation)"

This collation type appears only in the [`ln` (Lingala)
collation](https://github.com/unicode-org/cldr/blob/release-43/common/collation/ln.xml#L20).
I don't have any actual knowledge about this, but it seems pretty
clear that this collation type modifies the order of some letters and
letter groups to be more phonetic.

## pinyin

Description: "Pinyin ordering for Latin and for CJK characters (used in Chinese)"

This collation type appears only in the [`zh` (Chinese)
collation](https://github.com/unicode-org/cldr/blob/release-43/common/collation/zh.xml#L28).
Pinyin is a romanization system for Chinese characters.  So this
collation basically sorts Chinese characters in accordance with their
Latin-alphabet analogs.

## reformed

Description: "Reformed ordering (such as in Swedish)"

This collation type currently does not appear in any collation.  It
previously appeared in the [`sv` (Swedish)
collation](https://github.com/unicode-org/cldr/blob/release-43/common/collation/sv.xml).
In July 2022, the "reformed" collation for Swedish was renamed to
"standard" and the previous standard one to "traditional".

The only difference between the reformed (now standard) type and
the traditional (previous standard) type is that the reformed
type drops the rule

```
&v<<<V<<w<<<W
```

which means to sort w/W as second-level variants of v/V.

See also [`trad`](#trad).

## search

Description: "Special collation type for string search"

This collation type appears in the [root
collation](https://github.com/unicode-org/cldr/blob/release-43/common/collation/root.xml#L20)
and a number of language-specific collations.  (But as far as I can
tell, most if not all of those appearances in language-specific files
just import the search rules from the root and then apply the
language-specific standard rules.  There don't appear to be many
language-specific _search_ rules, but I haven't checked this
exhaustively.)

The description from UTS #35 is:

> A special collation type dedicated for string search—it is not used
> to determine the relative order of two strings, but only to
> determine whether they should be considered equivalent for the
> specified strength, using the string search matching rules
> appropriate for the language. Compared to the normal collator for
> the language, this may add or remove primary equivalences, may make
> additional characters ignorable or change secondary equivalences,
> and may modify contractions to allow matching within them, depending
> on the desired behavior. For example, in Czech, the distinction
> between ‘a’ and ‘á’ is secondary for normal collation, but primary
> for search; a search for ‘a’ should never match ‘á’ and vice
> versa. A search collator is normally used with strength set to
> PRIMARY or SECONDARY (should be SECONDARY if using “asymmetric”
> search as described in the [UCA] section Asymmetric Search). The
> search collator in root supplies matching rules that are appropriate
> for most languages (and which are different than the root collation
> behavior); language-specific search collators may be provided to
> override the matching rules for a given language as necessary.

Interestingly, the cited Czech example no longer appears in CLDR.  It
was removed in 2016.  The
[rationale](https://unicode-org.atlassian.net/jira/software/c/projects/CLDR/issues/CLDR-9363)
given was:

> The change is partly because Czech users have become accustomed to
> the way Google search works in Czech; and since web search is the
> most common search behavior, it creates expectations for other
> search behavior.

So there you go.

Most of the search rules in the root collation concern non-Latin
alphabets such as Arabic and Korean, about which I know very little,
so I won't try to dig into that.

One rule that I can decipher is

```
# root search rules for Symbols
&'='<'≠'
```

This means to make the not-equals sign sort after the equals sign with
a primary difference.

The default collation weights for these characters are:

```
003D  ; [*06A2.0020.0002] # EQUALS SIGN
2260  ; [*06A2.0020.0002][.0000.002F.0002] # NOT EQUAL TO
```

This treats the not-equals sign sort of like an accent (secondary
difference) on the equals sign.  This probably makes sense for
_sorting_, but it could behave strangely when _searching_.

If you make a collation with primary strength, your search would do
this:

```sql
create collation c1 (provider = icu,
                     locale = 'und-u-co-standard-ks-level1',
                     deterministic = false);

select * from (values (u&'x\003Dy'), (u&'x\2260y')) _(x)
    where x collate c1 = 'x=y';
  x
-----
 x=y
 x≠y
```

which might be undesirable.  If you use the search collation type, you
will get a better behavior:

```sql
create collation c2 (provider = icu,
                     locale = 'und-u-co-search-ks-level1',
                     deterministic = false);

select * from (values (u&'x\003Dy'), (u&'x\2260y')) _(x)
    where x collate c2 = 'x=y';
  x
-----
 x=y
```

(PostgreSQL note: It is necessary to use the deterministic = false
property for collations here.)

## searchjl

Description: "Special collation type for Korean initial consonant search"

This collation type appears only in the [`ko` (Korean)
collation](https://github.com/unicode-org/cldr/blob/release-43/common/collation/ko.xml#L782).

## standard

Description: "Default ordering for each language"

This is the default.  So specifying a collation as, for example,
`en-u-co-standard` is equivalent to just writing `en`.

## stroke

Description: "Pinyin ordering for Latin, stroke order for CJK characters (used in Chinese)"

This collation type appears only in the [`zh` (Chinese)
collation](https://github.com/unicode-org/cldr/blob/release-43/common/collation/zh.xml#L3904).

## trad

Description: "Traditional style ordering (such as in Spanish)"

This collation type appears in the collations
[`bn`&nbsp;(Bengali)](https://github.com/unicode-org/cldr/blob/release-43/common/collation/bn.xml#L21),
[`es`&nbsp;(Spanish)](https://github.com/unicode-org/cldr/blob/release-43/common/collation/es.xml#L27),
[`fi`&nbsp;(Finnish)](https://github.com/unicode-org/cldr/blob/release-43/common/collation/fi.xml#L22),
[`kn`&nbsp;(Kannada)](https://github.com/unicode-org/cldr/blob/release-43/common/collation/kn.xml#L22),
[`sa`&nbsp;(Sanskrit)](https://github.com/unicode-org/cldr/blob/release-43/common/collation/sa.xml#L43),
and
[`vi`&nbsp;(Vietnamese)](https://github.com/unicode-org/cldr/blob/release-43/common/collation/vi.xml#L25).

For example, the "traditional" Spanish collation has the additional rules

```
&C<ch<<<Ch<<<CH
&l<ll<<<Ll<<<LL
```

which sorts `ch` and `ll` as separate letters (primary difference) in
the alphabet.  This rule has been
[removed](https://www.rae.es/espanol-al-dia/exclusion-de-ch-y-ll-del-abecedario)
by the Spanish language academy.  But it remains available in CLDR/ICU
for those who need it.

Similarly, in other languages, some traditional rules are dropped over
time to make the language rules more suitable to the computer age (I
suppose).  See also under [`reformed`](#reformed) for when the new
rules are not yet ready to become the standard ones, and also
[`compat`](#compat) for a related idea.

## unihan

Description: "Pinyin ordering for Latin, Unihan radical-stroke ordering for CJK characters (used in Chinese)"

This collation type appears in the
[`ja`&nbsp;(Japanese)](https://github.com/unicode-org/cldr/blob/release-43/common/collation/ja.xml#L504),
[`ko`&nbsp;(Korean)](https://github.com/unicode-org/cldr/blob/release-43/common/collation/ko.xml#L891),
and
[`zh`&nbsp;(Chinese)](https://github.com/unicode-org/cldr/blob/release-43/common/collation/zh.xml#L10046)
collations.

Unihan refers to the [Han
unification](https://en.wikipedia.org/wiki/Han_unification) of
Japanese, Korean, and Chinese characters done in Unicode.

## zhuyin

Description: "Pinyin ordering for Latin, zhuyin order for Bopomofo and CJK characters (used in Chinese)"

This collation type appears only in the [`zh` (Chinese)
collation](https://github.com/unicode-org/cldr/blob/release-43/common/collation/zh.xml#L5913).
Zhuyin is a transliteration and writing system for Chinese.

## Summary

As you can see from this discussion, there are a variety of reasons
for having these alternative collation types.  Some of them are for
compatibility with previous practices or other standards, some of them
were short-lived experiments, some of them are for the needs of a
single language, a number of them are for the Chinese language in
particular.  (I found
<https://en.wikipedia.org/wiki/Written_Chinese#Dictionaries>
interesting on the latter.)  Actually, all of these collation types
are just a set of collation customization rules packaged up under a
name.  If your needs go beyond that, you can also write out the rules
yourself, which PostgreSQL will support starting in version 16.
