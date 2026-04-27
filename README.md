# gem skjvs

String key json value storage, i.e. keys are automatically converted to MD5, values are serialized to JSON.  
Replacement for `YAML::Store` and such.

## Installation

```console
$ gem install skjvs
```

## Usage

Only two methods are supported for now: `[]` and `[]=`.

```ruby
store = SKJVS::OneFile.new
store[123] = "2\n3"
assert_equal "2\n3", store[123]
```

Store file is meant to be accessible from multiple processes at the same time. Though the store file is thread-safe. But store object isn't, so for each thread do own `SKJVS::OneFile.new`.

## Benchmark

Compared to `YAML::Store`, `PStore`, `gem sequel` (sqlite).

<img width="623" height="475" alt="image" src="https://github.com/user-attachments/assets/72ab0f15-6aa4-484a-937a-64e44850fbfb" />

Loses to Sequel after `skjvs_store.txt` reaches 30 MB and corresponding `sqlite.db` reaches 100 KB.

<img width="627" height="472" alt="image" src="https://github.com/user-attachments/assets/3aab57b4-e53e-4b07-9ad1-a0402037f7cf" />

Not sure why file size difference is so big -- maybe because benchmark is too aritifical and values are duplicating, and sqlite spots it and compacts, idk, didn't debug, didn't profile.  
`rake benchmark` could be done better, could be split into first-fetch/fetch/write, etc. Later.

TODO: compare to https://github.com/ruby/sdbm, https://github.com/ruby/dbm, https://github.com/propublica/daybreak, etc.

## Notes

The `SKJVS::OneFile` is optimized for speed. Later the `SKJVS::TwoFiles` may be implemented for memory optimization.

By current design the store file isn't editing, only growing, so value overwriting creates extra line. You may want to compact the file by yourself (TODO: a tool), but only in between of its usage (for example, restart processes).

To better understand the design and trade-offs of test and benchmark, see automated TLDR:

<img width="1310" height="437" alt="image" src="https://github.com/user-attachments/assets/adab5221-0dc9-45dd-b1fd-b7e4cb1db9c6" />

## Development:

```console
$ bundle install
$ bundle exec ruby test.rb
$ bundle exec rake benchmark
```

```console
$ rake -rbundler/gem_tasks release
```
