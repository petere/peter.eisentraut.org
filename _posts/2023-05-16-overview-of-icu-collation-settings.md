---
title: "Overview of ICU collation settings"
comments: true
tags:
- icu
- postgresql
---

ICU use is becoming more [prominent]({% post_url
2022-09-26-icu-features-in-postgresql-15 %}) in PostgreSQL.  One of
the benefits that ICU offers is a lot of customization options for
collations.  Some of these are given as examples in the [PostgreSQL
documentation](https://www.postgresql.org/docs/15/collation.html), but
I have always found it hard to get complete and easily-accessible
information about this.

So for this article, I dug deeper and looked up all the collation
settings that there are and tried to work out examples for each one.

I recommend reading my previous article on [how collation works]({%
post_url 2023-03-14-how-collation-works %}).  But even if you haven't
done that, this should be interesting as an overview of the
possibilities.

That standard document to use as the starting point is [_Unicode
  Technical Standard #35: Unicode Locale Data Markup Language – Part
  5:
  Collation_](https://www.unicode.org/reports/tr35/tr35-collation.html).
  The primary purpose of that document (or document series) is to
  specify a way to specify locale data.  As part of it, it also
  specifies various settings and other ways to customize collations.

The other place to look is in the source code of CLDR, which is the
data that ICU actually uses:
<https://github.com/unicode-org/cldr/blob/main/common/bcp47/collation.xml>

Note that while the Unicode Collation Algorithm (UCA) and other
Unicode standards on the one side and ICU and CLDR on the other are
closely aligned, there are minor documented differences, for example
different defaults for some settings.  In practice, you can ignore the
UCA defaults and only pay attention to the ICU defaults, but it is
worth being aware of this when studying various documents.

There are two groups of collation customizations, and I will split
this article into two to keep it manageable:

* Parametric settings: These are settings that change the collation
  order in some algorithmic way independent of the underlying data or
  language.  An example of this is `und-u-ka-shifted` (see below).

* Settings that choose a collation variant defined in some other
  specification.  Examples of this are `und-u-co-emoji` and
  `de-u-co-phonebk`.

In this article, I'm going to look at the parametric settings in more
detail.  I'll leave the other settings for a future article.

You can also follow the more technical specification of the parametric
settings here:
<https://www.unicode.org/reports/tr35/tr35-collation.html#Collation_Settings>.
For each setting, I'm also going to quote the definition from the CLDR
XML file, for easy reference.

A note on specifying locale names: This could be a topic on its own,
but just to help understand the below: There are two ways to specify
locale names in ICU: The modern BCP 47 syntax like `en-u-kn-true` and
the old ICU-specific one like `en@colNumeric=yes`.  In this article,
I'm going to use the BCP 47 syntax throughout, but I'm using the
older, more verbose keys as section headings, for easier navigation.

The specification for BCP 47 is [RFC
5646](https://www.rfc-editor.org/rfc/rfc5646.html).  The `-u-` you see
in the examples below is the extension identifier
[registered](https://www.iana.org/assignments/language-tag-extensions-registry/language-tag-extensions-registry)
to Unicode.  The reference for that extension in turn is [RFC
6067](https://datatracker.ietf.org/doc/html/rfc6067), which points to
<https://cldr.unicode.org/index/bcp47-extension>, which then points to
the above XML file for collation-specific information.  (There are
other locale concerns beyond collation, such as calendars and number
formatting, which are covered by these specifications but are not
relevant to this article.)

I'm basing all the example locales on `und`, which stands for
"undetermined" and uses the language-neutral (as good as possible)
default order defined by UCA.

And a final note before we get started: All examples are with
PostgreSQL 15 and ICU 72.

## colAlternate

```xml
<key name="ka" description="Collation parameter key for alternate handling" alias="colAlternate">
    <type name="noignore" description="Variable collation elements are not reset to ignorable" alias="non-ignorable"/>
    <type name="shifted" description="Variable collation elements are reset to zero at levels one through three"/>
</key>
```

This setting determines how variable collation elements, such as
whitespace and punctuation, are handled.  I talked about this in
detail [in a previous article]({% post_url
2023-04-12-how-collation-of-punctuation-and-whitespace-works %}).

Here is a quick example:

```sql
create collation a (provider = icu, locale = 'und-u-ka-noignore');  -- default
create collation b (provider = icu, locale = 'und-u-ka-shifted');

select * from (values ('death'), ('deluge'), ('de luge')) _(x)
    order by x collate a;
    x
---------
 de luge
 death
 deluge

select * from (values ('death'), ('deluge'), ('de luge')) _(x)
    order by x collate b;
    x
---------
 death
 de luge
 deluge
```

Note that the ICU default is "noignore" but the UCA default is "shifted".

See the previous article for more details.

## colBackwards

```xml
<key name="kb" description="Collation parameter key for backward collation weight" alias="colBackwards">
    <type name="true" description="The second level to be backwards" alias="yes"/>
    <type name="false" description="No backwards (the second level to be forwards)" alias="no"/>
</key>
```

This setting causes the secondary weights (the accents) to be
backwards, meaning they are compared starting from the end of the
string.  This used to be used in French, but it is now obsolescent.

Example:

```sql
create collation a (provider = icu, locale = 'und-u-kb-false');  -- normal
create collation b (provider = icu, locale = 'und-u-kb-true');   -- backwards

select * from (values ('cote'), ('coté'), ('côte'), ('côté')) _(x)
    order by x collate a;
  x
------
 cote
 coté
 côte
 côté

select * from (values ('cote'), ('coté'), ('côte'), ('côté')) _(x)
    order by x collate b;
  x
------
 cote
 côte
 coté
 côté
```

As you can see here, the francophone world is apparently divided on this:

```sql
select * from (values ('cote'), ('coté'), ('côte'), ('côté')) _(x)
    order by x collate "fr-FR-x-icu";
  x
------
 cote
 coté
 côte
 côté

select * from (values ('cote'), ('coté'), ('côte'), ('côté')) _(x)
    order by x collate "fr-CA-x-icu";
  x
------
 cote
 côte
 coté
 côté
```

Again, this is being phased out in practice.  But it is an interesting
curiosity.

## colCaseLevel

```xml
<key name="kc" description="Collation parameter key for case level" alias="colCaseLevel">
    <type name="true" description="The case level is inserted in front of tertiary" alias="yes"/>
    <type name="false" description="No special case level handling" alias="no"/>
</key>
```

This setting allows for creating collations that ignore accents but
not case.  Using the [colStrength](#colstrength) (`ks`) setting, you
can ignore weights from the end, for example tertiary and beyond.  But
to allow ignoring accents but not case you want to ignore the
secondary weight but keep the tertiary.  That's what this setting
accomplishes.

Example:

```sql
create collation a (provider = icu,
                    locale = 'und-u-ks-identic', deterministic = false);
create collation b (provider = icu,
                    locale = 'und-u-kc-true-ks-level1', deterministic = false);

select distinct x collate a
    from (values ('foo'), ('Foo'), ('bar'), ('bär')) _(x);
  x
-----
 foo
 bar
 bär
 Foo

select distinct x collate b
    from (values ('foo'), ('Foo'), ('bar'), ('bär')) _(x);
  x
-----
 Foo
 foo
 bar
```

The above is probably the most common and obvious use case of this.

The more complete and complicated explanation is that this setting
creates an additional weight between the second and third level
(accordingly called the "2.5" level) that encodes the case
differences.  This virtual level is kept even if weights past the
primary one would otherwise be ignored, as in the above example.

I have so far always said that the third level encodes the case, but
that is not all it does.  It also encodes other minor variations of
characters.  Consider the following:

```
0061  ; [.2075.0020.0002] # LATIN SMALL LETTER A
24D0  ; [.2075.0020.0006] # CIRCLED LATIN SMALL LETTER A
00E4  ; [.2075.0020.0002][.0000.002B.0002] # LATIN SMALL LETTER A WITH DIAERESIS
0041  ; [.2075.0020.0008] # LATIN CAPITAL LETTER A
24B6  ; [.2075.0020.000C] # CIRCLED LATIN CAPITAL LETTER A
2090  ; [.2075.0020.0015] # LATIN SUBSCRIPT SMALL LETTER A
```

If we turn the colCaseLevel setting on, a notional "2.5" weight is
inserted that would look like this:

```
0061  ; [.2075.0020.0001.0002] # LATIN SMALL LETTER A
24D0  ; [.2075.0020.0001.0006] # CIRCLED LATIN SMALL LETTER A
00E4  ; [.2075.0020.0001.0002][.0000.002B.0001.0002] # LATIN SMALL LETTER A WITH DIAERESIS
0041  ; [.2075.0020.0003.0008] # LATIN CAPITAL LETTER A
24B6  ; [.2075.0020.0003.000C] # CIRCLED LATIN CAPITAL LETTER A
2090  ; [.2075.0020.0001.0015] # LATIN SUBSCRIPT SMALL LETTER A
```

Now we can create a collation that keeps the "2.5" weights but ignores
the original tertiary weights and beyond.  That collation maintains
the case distinction but ignores other third-level variations:

```sql
create collation c (provider = icu,
                    locale = 'und-u-kc-true-ks-level2', deterministic = false);

select distinct x collate a
    from (values (u&'\0061'),
                 (u&'\24D0'),
                 (u&'\00E4'),
                 (u&'\0041'),
                 (u&'\24B6'),
                 (u&'\2090')) _(x);
 x
---
 ₐ
 a
 Ⓐ
 ⓐ
 A
 ä

select distinct x collate b
    from (values (u&'\0061'),
                 (u&'\24D0'),
                 (u&'\00E4'),
                 (u&'\0041'),
                 (u&'\24B6'),
                 (u&'\2090')) _(x);
 x
---
 a
 A

select distinct x collate c
    from (values (u&'\0061'),
                 (u&'\24D0'),
                 (u&'\00E4'),
                 (u&'\0041'),
                 (u&'\24B6'),
                 (u&'\2090')) _(x);
 x
---
 ä
 a
 A
```

See <https://www.unicode.org/reports/tr35/tr35-collation.html#Case_Parameters> for more details.

## colCaseFirst

```xml
<key name="kf" description="Collation parameter key for ordering by case" alias="colCaseFirst">
    <type name="upper" description="Upper case to be sorted before lower case"/>
    <type name="lower" description="Lower case to be sorted before upper case"/>
    <type name="false" description="No special case ordering" alias="no"/>
</key>
```

This setting allows you to select whether lower or upper-case letters
should sort first.  By default, lower case letters sort first.

Example:

```sql
create collation a (provider = icu, locale = 'und-u-kf-lower');
create collation b (provider = icu, locale = 'und-u-kf-upper');

select * from (values ('foo'), ('Foo'), ('bar'), ('Bar')) _(x)
    order by x collate "und-x-icu";
  x
-----
 bar
 Bar
 foo
 Foo

select * from (values ('foo'), ('Foo'), ('bar'), ('Bar')) _(x)
    order by x collate a;
  x
-----
 bar
 Bar
 foo
 Foo

select * from (values ('foo'), ('Foo'), ('bar'), ('Bar')) _(x)
    order by x collate b;
  x
-----
 Bar
 bar
 Foo
 foo
```

This setting works with and without the [colCaseLevel](#colcaselevel)
(`kc`) setting.  If colCaseLevel is true, then the notional "2.5"
weight is modified to modify the case order.  For example, continuing
the earlier example, for a locale `und-u-kc-true-kf-upper`, the
notional adjusted weights would be:

```
0061  ; [.2075.0020.0003.0002] # LATIN SMALL LETTER A
24D0  ; [.2075.0020.0003.0006] # CIRCLED LATIN SMALL LETTER A
00E4  ; [.2075.0020.0003.0002][.0000.002B.0003.0002] # LATIN SMALL LETTER A WITH DIAERESIS
0041  ; [.2075.0020.0001.0008] # LATIN CAPITAL LETTER A
24B6  ; [.2075.0020.0001.000C] # CIRCLED LATIN CAPITAL LETTER A
2090  ; [.2075.0020.0003.0015] # LATIN SUBSCRIPT SMALL LETTER A
```

If colCaseLevel is false, the tertiary weight is modified.  For
example, for a locale `und-u-kf-upper` (`-kc-false`), the notional
weights would be:

```
0061  ; [.2075.0020.30002] # LATIN SMALL LETTER A
24D0  ; [.2075.0020.30006] # CIRCLED LATIN SMALL LETTER A
00E4  ; [.2075.0020.30002][.0000.002B.30002] # LATIN SMALL LETTER A WITH DIAERESIS
0041  ; [.2075.0020.10008] # LATIN CAPITAL LETTER A
24B6  ; [.2075.0020.1000C] # CIRCLED LATIN CAPITAL LETTER A
2090  ; [.2075.0020.30015] # LATIN SUBSCRIPT SMALL LETTER A
```

But this ends up providing the same order, unless additional options
further modify or ignore certain weight levels.

## colHiraganaQuaternary

```xml
<key name="kh" deprecated="true" description="Collation parameter key for special Hiragana handling" alias="colHiraganaQuaternary">
    <type name="true" description="Hiragana to be sorted before all non-variable on quaternary level" alias="yes"/>
    <type name="false" description="No special handling for Hiragana" alias="no"/>
</key>
```

[Hiragana](https://en.wikipedia.org/wiki/Hiragana) is part of the
Japanese writing system.  I am not familiar with that, so I won't try
to conjure up some example here.  UTS #35 also says: "Deprecated: Use
rules with quarternary relations instead."

## colNormalization

```xml
<key name="kk" description="Collation parameter key for normalization" alias="colNormalization">
    <type name="true" description="Convert text into Normalization Form D before calculating collation weights" alias="yes"/>
    <type name="false" description="Skip normalization" alias="no"/>
</key>
```

Ordinarily, strings are normalized to NFD form before collation.  With
this setting, this can be disabled.  This would give better
performance, but might behave incorrectly (or at least differently) in
some cases.

The default collation weights are set up so that normalization should
not matter in most cases.  For example, consider the composed and
decomposed forms of "LATIN SMALL LETTER A WITH DIAERESIS":

```
00E4  ; [.2075.0020.0002][.0000.002B.0002] # LATIN SMALL LETTER A WITH DIAERESIS

0061  ; [.2075.0020.0002] # LATIN SMALL LETTER A
0308  ; [.0000.002B.0002] # COMBINING DIAERESIS
```

These would result in exactly the same collation weights for a string
whether it is normalized or not.

There are a some cases where normalization does make a difference to
the collation.  These are described here:
<https://www.unicode.org/reports/tr35/tr35-collation.html#Normalization_Setting>

## colNumeric

```xml
<key name="kn" description="Collation parameter key for numeric handling" alias="colNumeric">
    <type name="true" description="A sequence of decimal digits is sorted at primary level with its numeric value" alias="yes"/>
    <type name="false" description="No special handling for numeric ordering" alias="no"/>
</key>
```

This setting causes sequences of digits to sort by their numeric value
(numeric ordering, also known as natural sort).

Example:

```sql
create collation a (provider = icu, locale = 'und-u-kn-false');  -- standard
create collation b (provider = icu, locale = 'und-u-kn-true');   -- numeric

select * from (values ('A-123'), ('A-12n'), ('A-21'), ('B-100')) _(x)
    order by x collate a;
   x
-------
 A-123
 A-12n
 A-21
 B-100

select * from (values ('A-123'), ('A-12n'), ('A-21'), ('B-100')) _(x)
    order by x collate b;
   x
-------
 A-12n
 A-21
 A-123
 B-100
```

This can clearly be useful in practice, for sorting almost-numeric
things like some product or invoice numbers.

It also works for non-ASCII digits:

```sql
select * from (values ('१२३'), ('२१')) _(x) order by x collate a;
  x
-----
 १२३
 २१

select * from (values ('१२३'), ('२१')) _(x) order by x collate b;
  x
-----
 २१
 १२३
```


## colReorder

```xml
<key name="kr" description="Collation reorder codes" valueType="multiple" alias="colReorder" since="21">
    <type name="space" description="Whitespace reordering code, see LDML Part 5: Collation" since="21"/>
    <type name="punct" description="Punctuation reordering code, see LDML Part 5: Collation" since="21"/>
    <type name="symbol" description="Symbol reordering code (other than currency), see LDML Part 5: Collation" since="21"/>
    <type name="currency" description="Currency reordering code, see LDML Part 5: Collation" since="21"/>
    <type name="digit" description="Digit (number) reordering code, see LDML Part 5: Collation" since="21"/>
    <type name="REORDER_CODE" description="Other collation reorder code — for script, see LDML Part 5: Collation" since="21"/>
</key>
```

This setting allows reordering whole blocks of characters relative to
each other.  For example, by default, digits sort before Latin
letters, and Latin letters sort before Cyrillic letters.  Someone had
to pick some default order, and that's what it ended up with.  With
this setting, you can easily specify, sort Cyrillic before Latin
letters, and digits after, without having to reorder each character
separately.  There are many possible values here, including more
alphabets and other groups of characters, such as the ones shown in
the XML source.

Example:

```sql
create collation a (provider = icu, locale = 'und');
create collation b (provider = icu, locale = 'und-u-kr-cyrl-latn-digit');

select * from (values ('123'), ('România'), ('България'), ('Србија')) _(x)
    order by x collate a;
    x
----------
 123
 România
 България
 Србија

select * from (values ('123'), ('România'), ('България'), ('Србија')) _(x)
    order by x collate b;
    x
----------
 България
 Србија
 România
 123
```

Note that language-specific locales may override the default ordering.
For example, the Bulgarian locale puts the Cyrillic script first:

```sql
select * from (values ('123'), ('România'), ('България'), ('Србија')) _(x)
    order by x collate "bg-x-icu";
    x
----------
 123
 България
 Србија
 România
```

See
<https://www.unicode.org/reports/tr35/tr35-collation.html#Script_Reordering>
for more details.

## colStrength

```xml
<key name="ks" description="Collation parameter key for collation strength" alias="colStrength">
    <type name="level1" description="The primary level" alias="primary"/>
    <type name="level2" description="The secondary level" alias="secondary"/>
    <type name="level3" description="The tertiary level" alias="tertiary"/>
    <type name="level4" description="The quaternary level" alias="quaternary quarternary"/>
    <type name="identic" description="The identical level" alias="identical"/>
</key>
```

This specifies how many levels of collation weights are taken into
account.  The other levels are simply ignored.  A typical use of this
is case-insensitive collation, by ignoring the third and following
levels.  (Recall that the second level is accents, the third is case.)

Example:

```sql
create collation a (provider = icu,
                    locale = 'und-u-ks-identic', deterministic = false);
create collation b (provider = icu,
                    locale = 'und-u-ks-level2', deterministic = false);

select distinct x collate a
    from (values ('foo'), ('Foo'), ('bar'), ('Bar')) _(x);
  x
-----
 foo
 bar
 Bar
 Foo

select distinct x collate b
    from (values ('foo'), ('Foo'), ('bar'), ('Bar')) _(x);
  x
-----
 foo
 bar
```

You can also ignore both case and accents:

```sql
create collation a (provider = icu,
                    locale = 'und-u-ks-identic', deterministic = false);
create collation b (provider = icu,
                    locale = 'und-u-ks-level1', deterministic = false);

select distinct x collate a
    from (values ('foo'), ('Foo'), ('bar'), ('bär')) _(x);
  x
-----
 foo
 bar
 bär
 Foo

select distinct x collate b
    from (values ('foo'), ('Foo'), ('bar'), ('bär')) _(x);
  x
-----
 bar
 foo
```

Note that you cannot use this by itself to ignore accents but not
case.  For that, you need to use the [colCaseLevel](#colcaselevel)
(`kc`) setting.

## maxVariable

```xml
<key name="kv" description="Collation parameter key for maxVariable, the last reordering group to be affected by ka-shifted" since="25">
    <type name="space" description="Only spaces are affected by ka-shifted" since="25"/>
    <type name="punct" description="Spaces and punctuation are affected by ka-shifted (CLDR default)" since="25"/>
    <type name="symbol" description="Spaces, punctuation and symbols except for currency symbols are affected by ka-shifted (UCA default)" since="25"/>
    <type name="currency" description="Spaces, punctuation and all symbols are affected by ka-shifted" since="25"/>
</key>
```

This specifies which characters are to be variable collation elements,
which are affected by the [colAlternate](#colalternate) (`ka`)
setting.  In my previous article on this, I always talked about
"whitespace and punctuation", but as you can see here, other groups of
characters can also be considered.

Let's look at an example:

```sql
create collation a (provider = icu, locale = 'und-u-ka-shifted');
create collation b (provider = icu, locale = 'und-u-ka-shifted-kv-currency');

select * from (values ('death'), ('deluge'), ('de luge'), ('de$luge')) _(x)
    order by x collate a;
    x
---------
 de$luge
 death
 de luge
 deluge

select * from (values ('death'), ('deluge'), ('de luge'), ('de$luge')) _(x)
    order by x collate b;
    x
---------
 death
 de luge
 de$luge
 deluge
```

Note how in the first example, the currency character `$` sorts like a
non-variable character, before the character `a`, while in the second
example, it is affected by the same variable treatment as the space
character.

By default, spaces and punctuation are treated as variable in CLDR,
whereas UCA also treats symbols as variable by default.

## variableTop

```xml
<key name="vt" deprecated="true" description="Collation parameter key for variable top" valueType="multiple" alias="variableTop">
    <type name="CODEPOINTS" description="The variable top (one or more Unicode code points: LDML Appendix Q)"/>
</key>
```

This is a deprecated alternative to [maxVariable](#maxvariable) where
instead of specifying variable characters by group names, you select
the variable characters by specifying that all characters with a
primary weight below a certain value (the "top") should be variable.
This is clearly less convenient than the alternative, so it is
deprecated.

## Summary

Here is a summary of the discussed collation settings, ignoring the
officially deprecated ones:

|---------------------------------------|-----|----------------------------------------------------|
| Alias                                 | Key | Description                                        |
|---------------------------------------|-----|----------------------------------------------------|
| [colAlternate](#colalternate)         | ka  | alternate handling                                 |
| [colBackwards](#colbackwards)         | kb  | backward collation weight                          |
| [colCaseLevel](#colcaselevel)         | kc  | case level                                         |
| [colCaseFirst](#colcasefirst)         | kf  | ordering by case                                   |
| [colNormalization](#colnormalization) | kk  | normalization                                      |
| [colNumeric](#colnumeric)             | kn  | numeric handling                                   |
| [colReorder](#colreorder)             | kr  | reorder codes                                      |
| [colStrength](#colstrength)           | ks  | collation strength                                 |
| [maxVariable](#maxvariable)           | kv  | last reordering group to be affected by ka-shifted |
|---------------------------------------|-----|----------------------------------------------------|

As mentioned at the beginning, I will look at the (non-parametric)
`collation`/`co` settings in another article in the future.
