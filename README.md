# Matcher

[![CI](https://github.com/rjasper/ruby-matchers/actions/workflows/ci.yml/badge.svg)](https://github.com/rjasper/ruby-matchers/actions/workflows/ci.yml)

A Ruby gem for validating nested data structures.

Whether you're checking API responses, configuration files, AI output, or
asserting complex structures in tests — writing validation for nested data by
hand gets tedious fast, and the errors are usually vague. Instead of an opaque
`assert_equal` diff on a large hash, this gem tells you exactly where things
went wrong: `root[:users][1][:age]: expected a value >= 18 but got 12`.

You describe the expected structure using a DSL that mirrors the shape of the
data. Ruby literals like classes, ranges, and regexps become matchers
automatically.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add matchers

If bundler is not being used to manage dependencies, install the gem by
executing:

    $ gem install matchers

## Docs

- [Quick Reference](doc/quick-reference.md)
- Guide:
    - [Basics](doc/guide-1-basics.md)
    - [Arrays](doc/guide-2-arrays.md)
    - [Hashes](doc/guide-3-hashes.md)
    - [Enumerables](doc/guide-4-enumerables.md)
    - [Combining](doc/guide-5-combine-matchers.md)
    - [Calls](doc/guide-6-calls.md)
    - [Strings](doc/guide-7-strings.md)
    - [Expressions](doc/guide-8-expressions.md)
    - [ExpressionMatchers](doc/guide-9-expression-matchers.md)
    - [Miscellaneous](doc/guide-10-misc.md)
    - [Recursive Matchers](doc/guide-11-refs.md)
    - [Custom Matchers](doc/guide-12-custom-matchers.md)

## Examples

Validate a file manifest — check paths, verify checksums against content, and
parse timestamps:

```ruby
require "digest"

matcher = Matcher.build do
  {
    files: each({
      path: of(String) & _.start_with?("/"),
      size: _.positive?,
      content: String,
      checksum: lazy_all(
        /\A[a-f0-9]{8}\z/, # 8-char hex string
        _ == expr(Digest::MD5).hexdigest(parent[:content])[0, 8] # matches content
      ),
      uploaded_at: parse_iso8601 ^ (_ >= Time.new(2025, 1, 1)),
    }),
  }
end

errors = matcher.match({
  files: [
    {
      path: "relative/path",
      size: 0,
      content: "hello",
      checksum: "not-a-checksum",
      uploaded_at: "not-a-date",
    },
    {
      path: "/valid/path",
      size: 100,
      content: "data",
      checksum: Digest::MD5.hexdigest("wrong content")[0, 8],
      uploaded_at: "2024-06-01T00:00:00Z",
    },
  ],
})
puts errors.report
# > root[:files][0][:path]: expected actual.start_with?("/") to be truthy but got false, where actual = "relative/path"
# > root[:files][0][:size]: expected value to be positive but got 0
# > root[:files][0][:checksum]: expected value to match /\A[a-f0-9]{8}\z/ but got "not-a-checksum"
# > root[:files][0][:uploaded_at]: expected a valid iso8601 string but got "not-a-date"
# > root[:files][1][:checksum]: expected actual == Digest::MD5.hexdigest(parent[:content])[0, 8] but got "5cabbd5b" == "8d777f38", where parent = { ... }
# > Time.iso8601(root[:files][1][:uploaded_at]): expected a value >= 2025-01-01 00:00:00 +0100 but got 2024-06-01 00:00:00 UTC
```

### Start simple

Ruby literals are matchers automatically — classes, ranges, regexps, arrays,
and hashes all work out of the box:

```ruby
matcher = Matcher.build do
  {
    name: String,
    age: 0..150,
    email: /@/,
    tags: each(String),
  }
end

matcher.match?({ name: "Alice", age: 30, email: "alice@example.com", tags: ["admin"] })
# => true

errors = matcher.match({ name: nil, age: -1, email: "invalid", tags: [42] })
puts errors.report
# > root[:name]: expected a kind of String but got nil
# > root[:age]: expected value to be between 0 and 150 but got -1
# > root[:email]: expected value to match /@/ but got "invalid"
# > root[:tags][0]: expected a kind of String but got 42
```

### Combine matchers

Matchers combine with `&` (and), `|` (or), and `~` (negate).

```ruby
matcher = Matcher.build do
  {
    id: any(String, Integer),
    score: of(Integer) & _.positive?,
    status: ~equal("deleted"),
  }
end

errors = matcher.match({ id: nil, score: -5, status: "deleted" })
puts errors.report
# > expected at least one error to be absent:
# > - root[:id]: expected a kind of String but got nil
# > - root[:id]: expected a kind of Integer but got nil
# > root[:score]: expected value to be positive but got -5
# > root[:status]: did not expect "deleted"
```

See also `one`, `>>` (imply) and more:

```ruby
of(String) >> (_.length <= 255) # if it's a String, it must be short
```

See [combining matchers](doc/guide-5-combine-matchers.md).

### Error tracing through transformations

After `map`, `filter`, or `dig`, errors still point to the position in the
original data.

```ruby
matcher = Matcher.build do
  filter(_.odd?) ^ each(_ < 10)
end

errors = matcher.match([2, 3, 4, 15, 6])
puts errors.report
# > root[3]: expected a value < 10 but got 15
```

The error reports index 3 in the original array, not index 1 in the filtered
result. See also `map`, `dig`, `index_by`, and `project`:

```ruby
project(_.to_i => 1..100, _.length => 1..3) # match projected values
```

See [enumerables](doc/guide-4-enumerables.md) and [calls](doc/guide-6-calls.md).

### Recursive structures

`refs` lets matchers reference themselves for trees and graphs.

```ruby
matcher = Matcher.build do
  refs[:node] = {
    value: Integer,
    children: each(refs[:node]),
  }
end

errors = matcher.match({
  value: 1,
  children: [
    { value: 2, children: [] },
    { value: "three", children: [] },
  ]
})
puts errors.report
# > root[:children][1][:value]: expected a kind of Integer but got "three"
```

See [Recursive Matchers](doc/guide-11-refs.md)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake test` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and the created tag, and push the `.gem` file
to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/rjasper/ruby-matchers. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [code of conduct](https://github.com/rjasper/ruby-matchers/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of
the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Matcher project's codebases, issue trackers, chat
rooms and mailing lists is expected to follow
the [code of conduct](https://github.com/rjasper/ruby-matchers/blob/master/CODE_OF_CONDUCT.md).
