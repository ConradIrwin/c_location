Given various assumptions about your setup, provides `Method#c_location`, which is the
equivalent of `Method#source_location` for methods that were written in C.

Requirements
============

On Mac OS X, you will need the `nm` tool that's bundled with Xcode; and the `gobjdump`
tool that you can get with `brew install binutils`.

On Linux you'll need the `objdump` tool, on Debian/Ubuntu it's obtainable with `apt-get install
binutils`, I assume other distros are similar.

On all systems you'll need your Rubies compiled with debug information (seems to be the
default on Linux). If you're using `rvm` add `export rvm_configure_flags="CFLAGS=-g"` to
`~/.rvmrc`.

If it still doesn't work — try running the commands that are found in
`lib/c_location/resolver.rb` manually, and see where the problem is.


How does this even work?!
=========================

1. Find a pointer to the C function that's behind a ruby method (most of the code in
   `ext/c_location.c` deals with doing this for various versions of Ruby — it's certainly
   not exposed in the API!)

2. Find the shared object file that contains this C function, and the offset in that file
   that the function's compiled code resides. This is done using the non-standard (but
   widespread) `dladdr()` function. (See man `dladdr`).

3. (Mac OS X only). Use `nm` to find the original library that the shared object file was
   built from. (This is because `.bundle` files don't contain the debugging information
   directly).

4. use `objdump` to read the DWARF data embedded in the shared object file when it was
   compiled with the `-g` flag.

5. Use some heuristics to guess the directories that might include that file based on the
   location of the object file on disk, and look for a correctly named file there.

(In short, lots and lots of string).


TODO
====

If possible, it'd be nice to have fewer external calls. Perhaps the data we're using `nm`
for could be done in Ruby without too much help; we could even try bundling `libdwarf` to
avoid the dependency on `objdump`.

It'd be really cool to make the Pry `edit-method` command work for C extensions. I think
this is just a matter of writing more code: have `edit-method` work as normal, and then
after closing the editor run `make` in the right directory; then copy the `.so` file into
a new directory and then require it. (the Init_foo method should then just overwrite all
the existing setup).

Meta-fu
=======

Released under the MIT License. Bug reports and pull requests welcome.

Do not use this in production :p.
