# Match Strings

## regexp

Pass MatchData to matcher:

```ruby
m = Matcher.build do
  regexp(/x=(\d+)/) ^ project(_[1].to_i) ^ _.between?(0, 10)
end

m.match?("x=5")
# => true
m.match("x=13")
# > root.match(/x=(\d+)/)[1].to_i: expected value to be between 0 and 10 but got 13
```

## integer_format

```ruby
m = Matcher.build { integer_format }

m.match?("12")
# => true
m.match("1.0")
# > root: expected a valid integer string but got "1.0"
```

## parse_integer

Pass parsed integer to matcher:

```ruby
m = Matcher.build { parse_integer(_.odd?) }

m.match?("7")
# => true
m.match("4")
# > Integer(root): expected value to be odd but got 4
```

## float_format

```ruby
m = Matcher.build { float_format }

m.match?("3.14")
# => true
m.match("one")
# > root: expected a valid float string but got "one"
```

## parse_float

Pass parsed float to matcher:

```ruby
m = Matcher.build { parse_float(_ > 0.0) }

m.match?("7.5")
# => true
m.match("-1.2")
# > Float(root): expected a value > 0.0 but got -1.2
```

## iso8601_format

```ruby
m = Matcher.build { iso8601_format }

m.match?("2025-11-16T21:13:33+01:00")
# => true
m.match("Once upon a time")
# > root: expected a valid iso8601 string but got "Once upon a time"
```

## parse_iso8601

Pass parsed time to matcher:

```ruby
m = Matcher.build { parse_iso8601(_ < expr { Time.now }) }

m.match?("1999-12-31T23:59:00+01:00")
# => true
m.match("2999-12-31T23:59:00+01:00")
# > Time.iso8601(root): expected actual < expr { ... } but got 2999-12-31 23:59:00 +0100 < 2025-11-16 21:18:15.367051472 +0100
```

## json_format

```ruby
m = Matcher.build { json_format }

m.match?('{"foo":42}')
# => true
m.match("invalid")
# > root: expected a valid json string but got "invalid"
```

## parse_json

Pass parsed time to matcher:

```ruby
m = Matcher.build do
  parse_json ^ { "foo" => Integer }
end

m.match?('{"foo":42}')
# => true
m.match('{"foo":"nan"}')
# > JSON.parse(root)["foo"]: expected a kind of Integer but got "nan"
```

---

Next: [Expressions](guide-8-expressions.md)  
Previous: [Calls](guide-6-calls.md)
