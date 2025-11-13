# Miscellaneous

## Chaining Helpers

Matcher helpers like `each` or `map` can be chained with the `^` operator or
`chain` helper. If a helper has the form `my_helper(..., matcher)` then it
usually also supports this form `my_helper(...) ^ matcher`. This helps reducing
nested parenthesis:

```ruby
# example:
let({ limit: 10 }, map(_.compact, filter(_.even?, _ < vars[:limit])))

# with chaining:
let(limit: 10) ^ map(_.compact) ^ filter(_.even?) ^ (_ < vars[:limit])
# OR
chain(let(limit: 10), map(_.compact), filter(_.even?), _ < vars[:limit])
```

Keep operator precedence in mind when working with expressions.

## optional

Match nil or given matcher:

```ruby
m = Matcher.build { optional(String) }

m.match?("Hello") # => true
m.match?(nil)     # => true
m.match?(1)       # => false
```

## present

Match given matcher but not nil:

```ruby
def definitely_not_nil
  nil # shoot
end

my_value = definitely_not_nil
m = Matcher.build { present(my_value) }
m.match?(nil) # => false

my_value = "fixed"
m = Matcher.build { present(my_value) }
m.match?("fixed") # => true
```

## always and never

Many matchers accept child matchers, for instance the HashMatcher. But before
they invoke a child matcher they often perform implicit checks. And sometimes,
we are only interested in those implicit checks and don't care about having a
child matcher.

Example:

```ruby
# Here we use "always" for the hash's value at :foo. But we don't care
# what the value actually is. We care only about whether there is a key :foo.
m = Matcher.build do
  { foo: always }
end

m.match?({ foo: "bar" })
# => true

m.match({})
# > root: expected to include key :foo but got {}
```

Where is the use-case for `never`? Can't think of one other than it's `~always`
and we really want to be able to negate matchers. Some matchers check whether
their child matcher is a `NeverMatcher` to provide a fitting error message.

## outside

Access context outside the build block:

```ruby
class MyClass
  def initialize
    @ivar = 42
  end

  def my_method
    "my string"
  end

  def my_matcher
    Matcher.build do
      # @ivar and self.my_method not accessible from here

      [outside { @ivar }, outside.my_method]
    end
  end
end

m = MyClass.new.my_matcher
m.match?([42, "my_string"]) # => true
```

---

Next: [Recursive Matchers](guide-11-refs.md)  
Previous: [ExpressionMatchers](guide-9-expression-matchers.md)
