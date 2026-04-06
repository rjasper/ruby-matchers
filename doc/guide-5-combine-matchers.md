# Combine Matchers

## neg `~`

Negate Matcher:

```ruby
m = Matcher.build { neg(1) } # OR
m = Matcher.build { ~equal(1) } # OR
m = ~Matcher.build { 1 }
m.match(1) # => root: did not expect 1
```

## all `*`

Match all matchers:

```ruby
m = Matcher.build { all(_ > 10, _.even?) } # OR
m = Matcher.build { of(_ > 10) * of(_.even?) }
m.match(9)
# > root: expected a value > 10 but got 9
# > root: expected value to be even but got 9
```

## lazy_all `&`

Evaluates matchers lazily and return last match result (similar to &&):

```ruby
m = Matcher.build { lazy_all(Integer, _ % 3 == 0) } # OR
m = Matcher.build { of(Integer) & _.positive? }

m.match("foo")
# > root: expected a kind of Integer but got "foo"
m.match(-1)
# > root: expected value to be positive but got -1
```

## any `+`

Match any matcher:

```ruby
m = Matcher.build { any(String, Integer) } # OR
m = Matcher.build { of(String) + of(Integer) }
m.match(:foo)
# > expected at least one error to be absent:
# > - root: expected a kind of String but got :foo
# > - root: expected a kind of Integer but got :foo
```

## lazy_any `|`

Evaluate matchers lazily and return last match result (similar to ||):

```ruby
m = Matcher.build { lazy_any(String, Integer) } # OR
m = Matcher.build { of(String) | of(Integer) }

m.match(:foo)
# > root: expected a kind of Integer but got :foo
```

## one

Match exactly one matcher:

```ruby
m = Matcher.build { one(_.include?(1), _.include?(2)) }

m.match([])
# > expected at least one error to be absent:
# > - root: expected 1 to be included but got []
# > - root: expected 2 to be included but got []

m.match([1, 2])
# > expected at least one error to be absent:
# > - root: did not expect 1 to be included but got [1, 2]
# > - root: did not expect 2 to be included but got [1, 2]
```

## imply `>>`

Match only for given condition:

```ruby
# if actual is a String, it must have length <= 4
m = Matcher.build { imply(String, _.length <= 4) } # OR
m = Matcher.build { of(String) >> (_.length <= 4) }

m.match?(1)
# => true (not a String, everything is fine)
m.match("foobar")
# > root: expected actual.length <= 4 but got 6 <= 4, where actual = "foobar"
```

## imply_one

Match exactly one implied matcher:

```ruby
# Strings should be lower case and integers positive. But it should either be
# a string or an integer. 
m = Matcher.build do
  imply_one(
    imply(String, _ == _.downcase),
    imply(Integer, _.positive?),
  )
end

m.match?("foo") # => true
m.match?(1) # => true

m.match("BAR")
# > root: expected actual == actual.downcase but got "BAR" == "bar"
m.match(-1)
# > root: expected value to be positive but got -1
m.match(nil)
# > expected at least one error to be absent:
# > - root: expected a kind of String but got nil
# > - root: expected a kind of Integer but got nil
```

## imply_any

Match at least one implied matcher:

```ruby
m = Matcher.build do
  imply_any(
    imply(_.even?, _ > 10),
    imply(_ % 3 == 0, _ < 20),
  )
end

m.match?(40) # => true
m.match?(9)  # => true
m.match?(12) # => true

m.match(8)
# > root: expected a value > 10 but got 8
m.match(21)
# > root: expected a value < 20 but got 21
m.match(15.5)
# > expected at least one error to be absent:
# > - root: expected an object responding to 'even?' but got 15.5
# > - root: expected actual % 3 == 0 but got 0.5 == 0, where actual = 15.5
```

---

Next: [Calls](guide-6-calls.md)  
Previous: [Enumerables](guide-4-enumerables.md)
