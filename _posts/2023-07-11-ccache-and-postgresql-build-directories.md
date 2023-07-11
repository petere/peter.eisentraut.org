---
title: "Ccache and PostgreSQL build directories"
comments: true
tags:
- ccache
- postgresql
---

We have talked [before]({% post_url
2023-05-29-postgresql-compile-times %}) about how
[ccache](https://ccache.dev/) affects build times of PostgreSQL.  Now
I was wondering how different build directory layouts affect ccache.
I was never a user of separate build directories in the make build
system ("vpath builds"), so this never concerned me much.  But now
with [Meson](https://www.postgresql.org/docs/16/install-meson.html)
this is required.

My question was: Can two build directories share ccache entries?

The [ccache
documentation](https://ccache.dev/manual/latest.html#_compiling_in_different_directories)
gives some information about this:

> Here’s what can be done to enable cache hits between different build directories:
>
> * If you build with `-g` (or similar) to add debug information to the object file, you must either:
>     * use the compiler option `-fdebug-prefix-map=<old>=<new>` for relocating debug info to a common prefix (e.g. `-fdebug-prefix-map=$PWD=.`); or
>     * set hash_dir = false.
>
> * If you use absolute paths anywhere on the command line (e.g. the
>   source code file path or an argument to compiler options like `-I`
>   and `-MF`), you must set base_dir to an absolute path to a “base
>   directory”. Ccache will then rewrite absolute paths under that
>   directory to relative before computing the hash.

During development, the first condition (`-g` option) is of course
true.  That means that without anything further, two build directories
cannot share cache hits.  You can observe this like this:

```
$ ccache --clear
$ ccache --zero-stats
$ meson setup _build1
$ meson compile -C _build1
# filled the cache:
$ ccache --show-stats
Cacheable calls:    1523 / 1760 (86.53%)
  Hits:               98 / 1523 ( 6.43%)
    Direct:            0 /   98 ( 0.00%)
    Preprocessed:     98 /   98 (100.0%)
  Misses:           1425 / 1523 (93.57%)
Uncacheable calls:   237 / 1760 (13.47%)
Local storage:
  Cache size (GiB):  0.1 /  5.0 ( 1.17%)
  Hits:               98 / 1523 ( 6.43%)
  Misses:           1425 / 1523 (93.57%)
```

```
$ ccache --zero-stats
$ meson setup _build2
$ meson compile -C _build2
# did *not* use the cache
$ ccache --show-stats
Cacheable calls:    1523 / 1760 (86.53%)
  Hits:              100 / 1523 ( 6.57%)
    Direct:            0 /  100 ( 0.00%)
    Preprocessed:    100 /  100 (100.0%)
  Misses:           1423 / 1523 (93.43%) <===
Uncacheable calls:   237 / 1760 (13.47%)
Local storage:
  Cache size (GiB):  0.1 /  5.0 ( 2.34%)
  Hits:              100 / 1523 ( 6.57%)
  Misses:           1423 / 1523 (93.43%)
```

If you set the option `hash_dir = false` as instructed (for example,
in `~/.config/ccache/ccache.conf`, or `export CCACHE_HASHDIR=false`),
then you will get 100% cache hits on the second run:

```
$ ccache --zero-stats
$ meson setup _build2
$ meson compile -C _build2
# using the cache now:
$ ccache --show-stats
Cacheable calls:    1523 / 1760 (86.53%)
  Hits:             1510 / 1523 (99.15%)
    Direct:         1510 / 1510 (100.0%) <===
    Preprocessed:      0 / 1510 ( 0.00%)
  Misses:             13 / 1523 ( 0.85%)
Uncacheable calls:   237 / 1760 (13.47%)
Local storage:
  Cache size (GiB):  0.1 /  5.0 ( 1.18%)
  Hits:             1510 / 1523 (99.15%)
  Misses:             13 / 1523 ( 0.85%)
```

(Observation: After turning off `hash_dir`, the cache needs to be
populated again.  It does not work to use a cache populated with
`hash_dir` enabled after `hash_dir` is turned off.)

The ccache documentation has
[caveats](https://ccache.dev/manual/latest.html#config_hash_dir) about
this option:

> The reason for including the CWD in the hash by default is to
> prevent a problem with the storage of the current working directory
> in the debug info of an object file, which can lead ccache to return
> a cached object file that has the working directory in the debug
> info set incorrectly.

I'm not really sure what that means in practice.  I'll keep an eye out
for it, but for now I'm trying this configuration.  I'm also finding a
lot of recommendations for this setting around the internet in the
context of other projects, so it doesn't seem completely insane.

This alternative solution mentioned in the ccache documentation is to
use the `-fdebug-prefix-map` option.  This is being discussed in a
[Meson issue](https://github.com/mesonbuild/meson/issues/10533), but
it's not done yet.  This would hopefully provide a built-in solution
eventually.

(I once tried to get that working in the configure/make build, but it
was tricky and ended up with essentially the same same problems
discussed in the Meson issue.)

The second condition above (absolute paths) is sometimes true.  If you
use make vpath builds, then the source directory is located via an
absolute path that includes the name of the build directory.  If you
use Meson, then, as far as I can tell, the paths to the source
directory are always relative, so it's not a problem in this context.

Of course, if you are using multiple build directories from the same
source, you usually do this because you are building with different
configurations, so ccache might not apply anyway.  The reason I'm
looking into this is that I'm sometimes trying a different
configuration (different compiler, different optimizations)
temporarily.  Knowing that ccache is effective, I can blow away the
build directory after I'm done and I won't have to remember what I
called the build directory last time I tried the same configuration.
