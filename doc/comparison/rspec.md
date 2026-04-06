# Comparison: RSpec Composable Matchers

RSpec's built-in `match` matcher supports composing matchers at arbitrary
depth. These examples come from the
[RSpec documentation](https://rspec.info/features/3-13/rspec-expectations/composing-matchers/).

## Deeply nested hash and array

```ruby
# RSpec
expect(response).to match(
  status: "ok",
  data: {
    users: [
      { name: an_instance_of(String), role: "admin" },
      { name: an_instance_of(String), role: "user" },
    ],
  },
  total: (a_value >= 1),
)

# matchers
matcher = Matcher.build do
  {
    status: "ok",
    data: {
      users: [
        { name: String, role: "admin" },
        { name: String, role: "user" },
      ],
    },
    total: _ >= 1,
  }
end
```

## Array of hashes with include

```ruby
# RSpec
expect(worker.queue).to match [
  a_hash_including(klass: "Class1", id: 37),
  a_hash_including(klass: "Class2", id: 42),
]

# matchers
matcher = Matcher.build do
  [
    partial(klass: "Class1", id: 37),
    partial(klass: "Class2", id: 42),
  ]
end
```

## Hash values with regex

```ruby
# RSpec
expect(a: "food", b: "good").to include(
  a: a_string_matching(/foo/)
)

# matchers
matcher = Matcher.build do
  partial(a: /foo/)
end
```

## Compound matcher expressions (and/or)

```ruby
# RSpec — and
expect("food").to start_with("f").and end_with("d")

# matchers
matcher = Matcher.build do
  all(
    _.start_with?("f"),
    _.end_with?("d"),
  )
end

# RSpec — or
expect(42).to be_a(String).or be_a(Integer)

# matchers
matcher = Matcher.build do
  any(String, Integer)
end
```

## Matching raised errors

```ruby
# RSpec
expect {
  nil.foo # oops
}.to raise_error(NoMethodError, a_string_starting_with("undefined method"))

# matchers
matcher = Matcher.build do
  raises(_.foo, NoMethodError, message: _.start_with?("undefined method"))
end

matcher.match?(nil)
```
