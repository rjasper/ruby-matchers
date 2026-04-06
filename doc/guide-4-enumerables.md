# Match Enumerable Objects

## each

Match each item:

```ruby
m = Matcher.build { each(Integer) }

m.match?([1, 2, 3])
# => true
m.match([1, "foo"])
# > root[1]: expected a kind of Integer but got "foo"

# "each" passes index and parent to its item matcher:
m = Matcher.build { each(_ == i) }
m.match?([0, 1]) # => true
m.match?([0, 2]) # => false

m = Matcher.build { each(_ < parent.length) }
m.match?([1, 0, 2]) # => true
m.match?([1, 2, 3]) # => false
```

## map

Map items to another value before matching:

```ruby
m = Matcher.build { map(_.to_i, [1, 2]) } # OR
m = Matcher.build { map(_.to_i) ^ [1, 2] }

m.match?(["1", "2"])
# => true
m.match(["1", :foo])
# > root[1]: expected an object responding to 'to_i' but got :foo
m.match(["1", "3"])
# > root[1].to_i: expected 2 but got 3

m = Matcher.build { map(_.to_i, _.sum == 3) }
m.match?(["1", "2"])
# => true
m.match(["1", "2", "3"])
# > root.map(&:to_i): expected actual.sum == 3 but got 6 == 3, where actual = [1, 2, 3]
```

## filter

Match only certain elements of an array:

```ruby
m = Matcher.build { filter(_.odd?, [1, 3, 5]) } # OR
m = Matcher.build { filter(_.odd?) ^ [1, 3, 5] }

m.match?([1, 2, 3, 4, 5])
# => true
m.match([1, 2, 3, 3, 5])
# > root.filter(&:odd?): expected length of 3 but was 4
# > root[3]: expected 5 but got 3
```

## index_by

Turn an array into a hash:

This is really useful when validating an array of items where the order
shouldn't matter.

```ruby
m = Matcher.build do
  index_by(_[:name], {
    "foo" => { name: "foo", value: 1 },
    "bar" => { name: "bar", value: 2 },
  })
end
# OR
m = Matcher.build do
  index_by(_[:name]) ^ {
    "foo" => { name: "foo", value: 1 },
    "bar" => { name: "bar", value: 2 },
  }
end

m.match?([
  { name: "foo", value: 1 },
  { name: "bar", value: 2 },
])
# => true

m.match?([
  { name: "bar", value: 2 },
  { name: "foo", value: 1 },
])
# => true

m.match([
  { name: "foo", value: 7 },
])
# > root[0][:value]: expected 1 but got 7
# > root.to_h { |e| [e[:name], e] }: expected to include key "bar" but got {"foo" => {name: "foo", value: 7}}
```

## equal_set

Match array elements like a set:

```ruby
m = Matcher.build { equal_set(1, 2, 3) }

m.match?([1, 2, 3]) # => true
m.match?([3, 2, 1]) # => true

m.match([1, 1, 3])
# > root[1]: did not expect duplicate originally at index 0 but got 1
# > root: expected 2 to be included but got [1, 1, 3]
```

---

Next: [Combining](guide-5-combine-matchers.md)  
Previous: [Hashes](guide-3-hashes.md)
