# Build Expressions

Expressions are a central feature of this library. They are used for:

- building ad-hoc matchers (e.g. `_ > 10`, `_.even?`)
- tracking where match errors happen (e.g. `root[:name]: expected ...`)
- as parameters for other matchers like `map` where they take the role of
  anonymous functions (e.g. `map(_.to_s, "some_string")`)

Helpers (like `map`) prefer expressions over procs because the AST of an
Expression can be inspected and transformed. This is useful for building
the path and message of errors.

```ruby
my_expression = Matcher::Expression.build { _ * 21 }
my_expression.evaluate(actual: 2) # => 42

# proc equivalent:
->(x) { x * 21 }
```

## How to build expressions with recorders

The core building block of composing expressions is a method *call*. For
instance,
`a + b` is a call where `a` receives `b` via its method `+`.

Our expression builder tracks Ruby calls with `Recorder` objects which work
like this:

```ruby
# let's build an AST for "Hello".upcase

# explicitly by hand
hello = Matcher::Constant.new("Hello")
hello_upcase = Matcher::Call.new(hello, :upcase)
hello_upcase.evaluate({}) # => "HELLO"

# with recorder
hello = Matcher::Constant.new("Hello")
hello_rec = Matcher::Recorder.new(hello)
hello_upcase_rec = hello_rec.upcase # the magic
hello_upcase = Matcher::Recorder.to_expression(hello_upcase_rec) # => "Hello".upcase
hello_upcase.evaluate({}) # => "HELLO"

# with builder
Matcher::Expression.build do
  expr("Hello").upcase
end
```

When calling any method on a recorder we get a new recorder object. The new
recorder can then also record a call so chains of calls are possible
(e.g. `x.foo.bar`).

## Recorders are nasty

To do their job any call to a recorder must return a new recorder. But this
also makes them ill-behaved because methods like `==` or `is_a?` don't behave
like you expect them to. They don't have any methods defined (except `__id__`
and `__send__`). Instead, all calls are handled by method_missing.

The consequence:

```ruby
# let r be a recorder
r = Matcher::Recorder.new(Matcher::Variable.actual)

# everything below returns a recorder

r == nil # truthy
r != r # truthy
!r # truthy
!!r # still truthy
r.class # not Recorder (but a Recorder instance)
r.object_id # not an integer
r.to_s # not a string
```

This makes them very hard to deal with, should you encounter them where you
wouldn't expect them.

## Left side must be a Recorder

Another important lesson: Make sure when building calls that the receiver is a
recorder. Otherwise, you'll call the receiver immediately.

For example:

```ruby
# raises exception because Ruby can't add a recorder to 1.
1 + vars[:a]

# correct:
vars[:a] + 1 # => a + 1
expr(1) + vars[:a] # => 1 + a

# raises exception because Recorder#to_str won't return a string
[vars[:a], vars[:b]].join(" ")

# correct:
expr([vars[:a], vars[:b]]).join(" ") # => [a, b].join(" ")

# clears hash immediately, no exception raised!
{ vars[:foo] => vars[:bar] }.clear # => {}

# correct:
expr({ vars[:foo] => vars[:bar] }).clear # => { foo => bar }.clear
```

Calling Kernel methods (e.g. `Integer("1")`):

```ruby
# raises exception because Recorder#to_str won't return a string
Integer(vars[:a])

# correct:
kernel.Integer(vars[:a]) # => Integer(a)
```

## Calls with a block

It's possible to build calls with a block:

```ruby
exp = Matcher::Expression.build do
  _.map { |x| x * 2 }
end

exp.evaluate(actual: [1, 2]) # => [2, 4]
```

During build time the block acts like an expression builder
(e.g. like `Expression.build`), where its arguments are recorders. So the inside
of a block cannot be arbitrary but must follow the same rules as for building
other expressions.

```ruby
# WRONG
Matcher::Expression.build do
  _.map { |x| 2 * x } # cannot multiply 2 with a recorder
end
```

Support for symbol procs:

```ruby
exp = Matcher::Expression.build do
  _.map(&:to_i)
end

exp.evaluate(actual: ['1', '2']) # => [1, 2]
```

## Variables

The most important variable is `actual` (short: `_`). An ad-hoc expression
matcher may be build like this:

```ruby
# matches anything below 10
Matcher.build { _ < 10 }
```

Some matchers set well-known variables before invoking a child matcher:

- `index` (short: `i`): index of current element
- `key` (short: `k`): key of current hash entry
- `value` (short: `v`): value of current hash entry
- `parent`: collection of the current element or hash value
- `original`: original value before mapping (see `map`)

Custom variables can be used with `vars`:

```ruby
# let a = 1: match if actual == a
m = Matcher.build { let({ a: 1 }, _ == vars[:a]) }
```

## Helpers

### expr: Turn any object to a recorder

```ruby
expr(Time).now
```

Note, that the arguments of a call are implicitly converted to expressions.
No need to use `expr` on the right-hand-side of an operator.

```ruby
# BAD
expr(Time).now + expr(3600)

# GOOD
expr(Time).now + 3600
```

This also works for deeply nested Hashes, Arrays and Sets:

```ruby
my_expr = Matcher::Expression.build do
  expr([{ foo: Set[vars[:a]] }])
end

my_expr.evaluate(a: 42) # => [{:foo=>#<Set: {42}>}]
```

### expr: Turn a block to a recorder

`expr { ... }`

```ruby
exp = Matcher::Expression.build do
  expr { |actual| actual ? 1 : 2 }
end

exp.evaluate(true)
# => 1

exp.inspect
# => "expr { ... }"
```

The disadvantage of block expressions is that we cannot inspect them easily. So
they should be avoided if possible. Alternatively, consider using inline
matchers or implement a new matcher class.

### range

`range(from, to, exclude_end: false)` where `from` and `to` can be expressions.

```ruby
exp = Matcher::Expression.build do
  range(0, vars[:limit])
end

exp.evaluate(limit: 10)
# => 0..10
```

### concat

`concat(*expressions)`

```ruby
exp = Matcher::Expression.build do
  concat('foo=', vars[:foo])
end

exp.evaluate(foo: 23)
# => "foo=23"
```

### assign

With `assign` we can capture calls to assignment methods:

```ruby
Matcher::Expression.build do
  assign { _.foo = 1 }
end
# => actual.foo = 1

Matcher::Expression.build do
  assign { _[:foo] = 1 }
end
# => actual[:foo] = 1
```

### logical_operators `lo`

We cannot capture `&&` and `||` directly when building expressions. But as a
workaround we can substitute them with `&` and `|`:

Note, that `&` and `|` have a different precedence than `&&` and `||`:

```ruby
Matcher::Expression.build do
  lo { vars[:foo] | vars[:bar] < 2 }
end

# => (foo || bar) < 2
```

### pass_through_blocks `ptb`

In the previous section we learned that a given block to a call is evaluated
during build time and is basically turned into an expression. Alternatively, we
can also disable this evaluation and pass it through:

```ruby
class Foo
  def initialize(foo)
    @foo = foo
  end
end

exp = Matcher::Expression.build do
  ptb do
    _.instance_exec { @foo }
  end
end

foo = Foo.new('foo')

exp.evaluate(actual: foo) # => 'foo'
```

---

Next: [Expression Matchers](guide-9-expression-matchers.md)  
Previous: [Strings](guide-7-strings.md)
