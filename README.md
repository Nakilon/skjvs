# gem skjvs

Replacement for `YAML::Store`.

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

Successfully compared to `YAML::Store`, `PStore`, `gem sequel` (sqlite).

...

`rake benchmark` could be done better and could be split into first-fetch/fetch/write, etc. Some day.

## Notes

By current design the store file isn't editing, only growing, so value overwriting creates extra line. You may want to compact the file by yourself (TODO: a tool), but only in between of its usage (for example, restart processes).

To understand the design and trade-offs of test and benchmark, see automated TLDR:

...

## Development:

```console
$ bundle install
$ bundle exec ruby test.rb
$ bundle exec rake benchmark
```

```console
$ rake -rbundler/gem_tasks release
```
