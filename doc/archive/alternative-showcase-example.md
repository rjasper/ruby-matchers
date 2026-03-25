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