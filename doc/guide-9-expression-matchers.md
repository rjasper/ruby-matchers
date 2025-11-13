# Expression Matchers

An expression matcher matches any object where the given expression returns a
truthy value:

```ruby
Matcher.build { _ > 0 }.match?(1) # => true
```

If an expression returns a falsy value an error message is generated:

```ruby
m = Matcher.build { (_ - 10).abs < 0.1 }
e = m.match(5)

puts e.report
# > root: expected (actual - 10).abs < 0.1 but got 5 < 0.1, where actual = 5
```

This is a generic error message, but few expressions will get recognized to
provide standardized messages. Here are some examples.

| Pattern                        | Example             | Message                                            |
|--------------------------------|---------------------|----------------------------------------------------|
| actual \<operator> \<operand>  | _ > 0               | expected a value > 0 but got -1                    |
| actual.\<predicate?>           | _.odd?              | expected value to be odd but got 2                 |
| actual.is_a?(\<class>)         | _.is_a?(Numeric)    | expected a kind of Numeric but got "zero"          |
| actual.respond_to?(\<operand>) | _.respond_to?(:foo) | expected an object responding to `foo' but got nil |
| actual.length == \<operand>    | _.length == 3       | expected length of 3 but was 2                     |
| actual.key?(\<operand>)        | _.key?(:foo)        | expected to include key :foo but got {}            |
| actual.include?(\<operand>)    | _.include?("a")     | expected "a" to be included but got "Hello"        |
| actual =~ \<operand>           | _ =~ /foo/          | expected value to match /foo/ but got "bar"        |

There are more rules that will also match slightly more generic expressions.
Have a look at `message_rules.rb` where all rules are defined.

## let

Use `let` to set variables which can be used in expressions.

```ruby
m = Matcher.build { let({ a: 1 }, _ == vars[:a]) } # OR
m = Matcher.build { let(a: 1) ^ (_ == vars[:a]) }

m.match?(1) # => true
```

---

Next: [Miscellaneous](guide-10-misc.md)  
Previous: [Expressions](guide-8-expressions.md)
