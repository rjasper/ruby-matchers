# Basics

```ruby
# Module or Class: match kind
Matcher.build { String }.match?("Hello World!")

# boolean: match true or false
Matcher.build { boolean }.match?(true)

# Range: match between
Matcher.build { 1..10 }.match?(5)

# Regexp: match pattern
Matcher.build { /Hello/ }.match?("Hello World!")

# Array: match all elements (see ArrayMatcher)
Matcher.build { [1, String] }.match?([1, "Hello"])

# Hash: match all entries (see HashMatcher)
Matcher.build { { a: 1, b: boolean } }.match?({ a: 1, b: false })

# other objects: match equal value (see EqualMatcher)
Matcher.build { 1 }.match?(1)
Matcher.build { equal(String) }.match?(String)

# Expression: match where evaluated expression is truthy (see ExpressionMatcher)
Matcher.build { _ > 10 }.match?(15)
Matcher.build { _.even? }.match?(4)
Matcher.build { _.length == 3 }.match?([1, 2, 3])
Matcher.build { _.include?("foo") }.match?(["foo", "bar"])
Matcher.build { expr(["foo", "bar"]).include?(_) }.match?("foo")
Matcher.build { _.sum(&:length) == 3 }.match?(["1", "23"])
```

The last examples showed what the expression matcher can do. Here you can learn
more about [expressions](/doc/guide-8-expressions.md) and
[expression matchers](/doc/guide-9-expression-matchers.md).

---

Next: [Arrays](guide-2-arrays.md)
