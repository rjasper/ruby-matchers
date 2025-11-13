# Matcher

TODO: Delete this and the text below, and describe your gem

Welcome to your new gem! In this directory, you'll find the files you need to be
able to package up your Ruby library into a gem. Put your Ruby code in the file
`lib/matcher`. To experiment with that code, run `bin/console` for an
interactive prompt.

## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_PRIOR_TO_RELEASE_TO_RUBYGEMS_ORG` with
your gem name right after releasing it to RubyGems.org. Please do not do it
earlier due to security reasons. Alternatively, replace this section with
instructions to install your gem from git if you don't plan to release to
RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

    $ bundle add UPDATE_WITH_YOUR_GEM_NAME_PRIOR_TO_RELEASE_TO_RUBYGEMS_ORG

If bundler is not being used to manage dependencies, install the gem by
executing:

    $ gem install UPDATE_WITH_YOUR_GEM_NAME_PRIOR_TO_RELEASE_TO_RUBYGEMS_ORG

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

## Example

```ruby
matcher = Matcher.build do
  {
    name: String,
    checksum: /\A[0-9a-f]{32}\z/,
    count: 1..10,
    size: [32, _.even?],
    value: _ < 100,
    not_zero: of(Integer) & ~equal(0),
  }
end

matcher.match?({
  name: 'test',
  checksum: '912ec803b2ce49e4a541068d495ab570',
  count: 2,
  size: [32, 16],
  value: 42,
  not_zero: 1
})
# => true

errors = matcher.match({
  name: nil,
  checksum: 'kS7IA7LOSeSlQQaNSVq1cA==',
  count: 0,
  size: [30, 15],
  value: 1337,
  not_zero: 0,
})

puts errors.report

# > root[:name]: expected a kind of String but got nil
# > root[:checksum]: expected value to match /\A[0-9a-f]{32}\z/ but got "kS7IA7LOSeSlQQaNSVq1cA=="
# > root[:count]: expected value to be between 1 and 10 but got 0
# > root[:size][0]: expected 32 but got 30
# > root[:size][1]: expected value to be even but got 15
# > root[:value]: expected a value < 100 but got 1337
# > root[:not_zero]: did not expect 0
```

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

Bug reports and pull requests are welcome on GitHub
at https://github.com/[USERNAME]/matcher. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [code of conduct](https://github.com/[USERNAME]/matcher/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of
the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Matcher project's codebases, issue trackers, chat
rooms and mailing lists is expected to follow
the [code of conduct](https://github.com/[USERNAME]/matcher/blob/master/CODE_OF_CONDUCT.md).
