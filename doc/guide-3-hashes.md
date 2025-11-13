# Match Hashes

```ruby
m = Matcher.build do
  { foo: 1 }
end

m.match?({ foo: 1 })
# => true
m.match({ foo: 0 })
# > root[:foo]: expected 1 but got 0
m.match({ foo: 1, bar: 1 })
# > root[:bar]: did not expect to include key :bar but got {:foo=>1, :bar=>2}

# Use matchers for values
m = Matcher.build { { foo: Integer } }
m.match?({ foo: 2 }) # => true
```

## Variables passed to value matchers

`HashMatcher` passes `key`, `value` and `parent` to its value matchers.

```ruby
# key
m = Matcher.build { { foo: _ == k.to_s } }
m.match?({ foo: "foo" })
# => true
m.match({ foo: "bar" })
# > root[:foo]: expected actual == key.to_s but got "bar" == "foo", where k = :foo

# parent
m = Matcher.build do
  {
    items: Array,
    length: equal(parent[:items].length),
  }
end

m.match({ items: [1], length: 10 })
# > root[:length]: expected 1 but got 10
```

## partial

Match hash partially:

```ruby
m = Matcher.build { partial(foo: 1) }
m.match?({ foo: 1, bar: 1 }) # => true (extra keys are ignored)

# recursive
m = Matcher.build { partial_r(foo: { bar: 1 }) }
# => partial({:foo=>partial({:bar=>1})})
m.match?({ foo: { bar: 1, baz: 2 }, qux: 3 }) # => true
```

## optional

Match value only if key included:

```ruby
m = Matcher.build do
  { optional(:foo) => 1 }
end

m.match?({})           # => true
m.match?({ foo: 1 })   # => true
m.match?({ foo: 2 })   # => false
m.match?({ foo: nil }) # => false
```

## others

Match remaining entries:

```ruby
m = Matcher.build do
  {
    id: Integer,
    others => each_value(String),
  }
end

m.match?({ id: 1, foo: "bar" })
# => true
m.match({ id: 1, foo: nil })
# > root[:foo]: expected a kind of String but got nil
```

## Expressions as keys

```ruby
m = Matcher.build do
  { vars[:my_key] => 1 }
end

m.match?({ foo: 1 }, my_key: :foo) # => true
```

## each_pair

Match all entries:

```ruby
m = Matcher.build { each_pair(k.to_s == v) } # OR
m = Matcher.build { each_pair ^ (k.to_s == v) }

m.match?({ foo: "foo" })
# => true
m.match({ foo: "bar" })
# > root[:foo]: expected key.to_s == value but got "foo" == "bar", where key = :foo
```

## each_key

```ruby
m = Matcher.build { each_key(Symbol) } # OR
m = Matcher.build { each_key ^ Symbol }

m.match?({ foo: 42 })
# => true
m.match({ "foo" => 42 })
# > root["foo"] -> key: expected a kind of Symbol but got "foo"
```

## each_value

```ruby
m = Matcher.build { each_value(String) } # OR
m = Matcher.build { each_value ^ String }

m.match?({ foo: "bar" })
# => true
m.match({ foo: false })
# > root[:foo]: expected a kind of String but got false
```

## keys

Match all keys:

```ruby
# keys
m = Matcher.build { keys(:foo, :bar) }

m.match?({ foo: 1, bar: 2 })
# => true
m.match({ foo: 1, qux: 3 })
# > root: expected to include key :bar but got {:foo=>1, :qux=>3}
# > root: did not expect to include key :qux but got {:foo=>1, :qux=>3}
```

## partial_keys

Given keys must be included. Extra keys are ignored.

```ruby
m = Matcher.build { partial_keys(:foo) }

m.match?({})
# => false
m.match?({ foo: 1 })
# => true
m.match?({ foo: 1, bar: 2 })
# => true
```

---

Next: [Enumerables](guide-4-enumerables.md)  
Previous: [Arrays](guide-2-arrays.md)
