# Comparison: Classy Hash

[Classy Hash](https://github.com/deseretbook/classy_hash) validates hashes using Ruby classes, ranges, regexps, and
lambdas as schema values.

## Type checks

```ruby
# Classy Hash
schema = { key1: String, key2: Integer, key3: TrueClass }
ClassyHash.validate(hash, schema)

# matchers
matcher = Matcher.build do
  { key1: String, key2: Integer, key3: boolean }
end
```

Note: Classy Hash uses `TrueClass` to mean "true or false". matchers uses the
explicit `boolean` helper.

## Union types

```ruby
# Classy Hash
schema = { key1: [NilClass, String, FalseClass] }

# matchers
matcher = Matcher.build do
  { key1: any(nil, String, false) }
end

# or, if the intent is "optional string or false":
matcher = Matcher.build do
  { key1: optional(String) | false }
end
```

## Regex and range constraints

```ruby
# Classy Hash
schema = {
  key1: /Re.*quired/i,
  key2: 1..10,
}

# matchers
matcher = Matcher.build do
  {
    key1: /Re.*quired/i,
    key2: 1..10,
  }
end
```

These are identical since both gems auto-convert regexps and ranges.

## Lambda validation

```ruby
# Classy Hash
schema = {
  key1: ->(v) { (v.is_a?(Integer) && v.odd?) || "an odd integer" }
}

# matchers
matcher = Matcher.build do
  { key1: of(Integer) & _.odd? }
end
```

matchers generates the error message automatically:
`root[:key1]: expected value to be odd but got 2`.

## Nested hashes

```ruby
# Classy Hash
schema = {
  key1: { msg: String },
  key2: { n1: [Integer, { y: Numeric }] },
}

# matchers
matcher = Matcher.build do
  {
    key1: { msg: String },
    key2: { n1: of(Integer) | { y: Numeric } },
  }
end
```

## Strict mode (no extra keys)

```ruby
# Classy Hash
ClassyHash.validate(hash, { c: Integer }, strict: true)

# matchers — hash matchers are strict by default
matcher = Matcher.build do
  { c: Integer }
end
```

matchers hashes are strict by default. Use `partial` for lenient matching.

## Collect all errors

```ruby
# Classy Hash
errors = []
ClassyHash.validate(hash, schema,
  errors: errors, raise_errors: false, full: true)

# matchers — always collects all errors, never raises
errors = matcher.match(hash)
puts errors.report
```
