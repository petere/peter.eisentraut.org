---
title: "Waiting for SQL:202y: Vectors"
comments: true
tags:
- postgresql
- sql
- sql:202y
---

It's been a while since [SQL:2023 was published]({% post_url
2023-06-01-sql-2023-is-out %}), and work on the SQL standard
continues.  Nowadays, everyone in the database field wants vectors,
and SQL now has them, too.

(I'm using the term "SQL:202y" for "the next SQL standard after
SQL:2023".  I took this naming convention from the [C
standard](https://thephd.dev/5-years-later-the-first-big-unicode-win-omg-yay),
but it's not an official term for the SQL standard.  The current
schedule suggests a new release in 2028, but we'll see.)

Vectors are a popular topic for databases now, related to LLM and "AI"
use cases.  There is lots of information about this out there; I'm
going to keep it simple here and just aim to describe the new SQL
features.  The basic idea is that you have some relational data in
tables, let's say textual product descriptions, or perhaps images.
And then you run this data through … something?, an LLM? — this part
is not covered by SQL at the moment — and you get a back vectors.  And
the idea is that vectors that are mathematically close to each other
represent semantically similar data.  So where before an application
might have searched for "matching" things by just string equality or
pattern matching or full-text search, it could now match semantically.
Many database management systems have added support for this now, so
it makes sense to standardize some of the common parts.

So there is now a new data type in SQL called `vector`:

<pre><code>CREATE TABLE items (
    id int PRIMARY KEY,
    somedata varchar,
    embedding <b>vector(100, integer)</b>
);</code></pre>

The `vector` type takes two arguments: A dimension count and a
coordinate type.  The coordinate type is either an existing numeric
type or possibly one of additional implementation-defined keywords.
For example, an implementation might choose to support vectors with
`float16` internal values.

Here is how you could insert data into this type:

<pre><code>INSERT INTO items VALUES (1, 'foo', <b>vector('[1,2,3,4,5,...]', 100, integer)</b>);</code></pre>

The `vector()` constructor takes a serialization of the actual vector
data and again a dimension count and a coordinate type.

Again, how you actually produce the data for this vector is not part
of the SQL standard.

There are a few utility functions for operating on this type, that I'm
not going to go into in detail about:

- `vector_dimension_count()`
- `vector_norm()`
- `vector_serialize()`

The main thing people want to do with vectors is compare them for
similarity with other vectors, and then sort by similarity.  There are
a number of different ways to calculate the vector similarity, and SQL
has support for several of them:

- `cosine`
- `dot`
- `euclidean`
- `euclidean_squared`
- `hamming`
- `manhattan`

These are used as part of the function `vector_distance()`, for
example:

<pre><code>SELECT *, <b>vector_distance(items.embedding, :someparam, cosine)</b> FROM items ...</code></pre>

(Here, `:someparam` is meant to represent some parameter to gets
plugged into the query by the application.)

Usually, what you want to do with the vector distance is not look at
it directly, but you want to order by the distance:

<pre><code>SELECT * FROM items ...
  ORDER BY <b>vector_distance(items.embedding, :someparam, cosine)</b></code></pre>

And usually you also want to apply some top-N limit:

<pre><code>SELECT * FROM items ...
  ORDER BY vector_distance(items.embedding, :someparam, cosine)
  FETCH FIRST 10 ROWS ONLY</code></pre>

(`FETCH FIRST` is SQL standard for what some SQL implementations might
also call `LIMIT`.)

An aspect that is particular to dealing with vectors is that people
are generally okay with approximate results.  If you run a query like,
"show me the top 10 department by sales, in order", you will surely
want exact and accurate results.  But if you do a vector-based query
like "give me the 10 closest matches for 'green shirt', in order", you
just need something good enough, and quickly, supported by some kind
of vector index that provides some level of good enough and quickly.
And then people use terms like _recall_ to adjudicate how good it was.

Indexes themselves are not part of the SQL standard, and so therefore
you will also not see any treatment of vector indexing, HNSW, or
whatever, in there.  This is up to the implementation.

Approximate results is not a concept that SQL has had so far (although
`TABLESAMPLE` is a bit like it).  To address this, the `FETCH FIRST`
clause has a new keyword `APPROX`, to select approximate results:

<pre><code>SELECT * FROM items ...
  ORDER BY vector_distance(items.embedding, :someparam, cosine)
  FETCH <b>APPROX</b> FIRST 10 ROWS ONLY</code></pre>

(The keyword for the opposite is `EXACT`.)  In practice, you probably
won't need to see this, because the rules also state that if the
vector type is used in a query, then `APPROX` is the default.

As an additional extension, you can now also specify a range as the
approximate limit, for example:

<pre><code>SELECT * FROM items ...
  ORDER BY vector_distance(items.embedding, :someparam, cosine)
  FETCH APPROX FIRST <b>5 TO 10</b> ROWS ONLY</code></pre>

This would ensure that you get somewhere between 5 and 10 rows.

That's all about this for the moment.  The SQL standard is still in
development, and there are also other features in the works that I
will possibly write about some other time.  In the meantime, it's also
possible to comment and provide feedback.  If you don't have access to
the official ISO channels, feel free to leave a comment here or
contact me directly.
