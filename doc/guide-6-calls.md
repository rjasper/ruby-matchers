# Invoke Methods

## project

Match the value of an expression:

```ruby
m = Matcher.build { project(_.to_i => _ < 10) } # OR
m = Matcher.build { project(_.to_i) ^ (_ < 10) }

m.match?("5")
# => true
m.match("15")
# > root.to_i: expected a value < 10 but got 15

# project multiple expressions
FooBar = Struct.new(:foo, :bar)

m = Matcher.build do
  project(
    _.foo => 1,
    _.bar => 2,
  )
end

m.match?(FooBar.new(1, 2))
# => true
```

## dig

Match deeply nested values:

```ruby
# also accepts expressions as keys
m = Matcher.build { dig(1, :a, vars[:b]) ^ Integer }

m.match?([0, { a: { "test" => 42 } }], b: "test")
# => true
m.match([])
# > root: expected to have index 1 but got []
```

## optional_dig

Match deeply nested value only if path exists:

```ruby
m = Matcher.build { optional_dig(:a, :b) ^ 1 }

m.match?({ a: {} })         # => true
m.match?({ a: { b: 1 } })   # => true
m.match?({ a: { b: 2 } })   # => false
m.match?({ a: nil })        # => false
m.match?({ a: { b: nil } }) # => false
```

## raises

Match raised error:

```ruby
m = Matcher.build { raises(_.fetch(:foo), KeyError) } # OR
m = Matcher.build { raises(_.fetch(:foo)) ^ KeyError }

m.match?({})
# => true
m.match({ foo: 1 })
# > root: expected actual.fetch(:foo) to raise StandardError, where actual = {foo: 1}

# match message
m = Matcher.build { raises(_.call, message: /something went wrong/) }
m.match(-> { raise "something went wrong" }) # => true

# pass block instead of expression:
m = Matcher.build do
  raises(NoMethodError) { |x| x.foo }
end
m.match?(nil) # => true

# rescue non-standard exceptions
m = Matcher.build { raises(_.call, rescue: Exception) }
m.match?(-> { raise Exception }) # => true
```

---

Next: [Strings](guide-7-strings.md)  
Previous: [Combining](guide-5-combine-matchers.md)
