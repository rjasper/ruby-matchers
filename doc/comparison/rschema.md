# Comparison: RSchema

[RSchema](https://github.com/tomdalling/rschema) is a composable schema validation gem with a Ruby DSL.

## Basic hash

```ruby
# RSchema
blog_post_schema = RSchema.define_hash {{
  title: _String,
  tags: array(_Symbol),
  body: _String,
}}

# matchers
matcher = Matcher.build do
  {
    title: String,
    tags: each(Symbol),
    body: String,
  }
end
```

## Fixed-length arrays (tuples)

```ruby
# RSchema
schema = RSchema.define { array(_Integer, _String) }

# matchers
matcher = Matcher.build do
  [Integer, String]
end
```

## Optional keys

```ruby
# RSchema
schema = RSchema.define_hash {{
  name: _String,
  optional(:age) => _Integer,
}}

# matchers
matcher = Matcher.build do
  {
    name: String,
    optional(:age) => Integer,
  }
end
```

Nearly identical syntax.

## Either (sum types)

```ruby
# RSchema
schema = RSchema.define { either(_String, _Integer, _Float) }

# matchers
matcher = Matcher.build do
  any(String, Integer, Float)
end
```

## Predicate

```ruby
# RSchema
schema = RSchema.define do
  predicate { |x| x.even? }
end

# matchers
matcher = Matcher.build do
  _.even?
end
```

## Pipeline (chained validators)

```ruby
# RSchema
schema = RSchema.define do
  pipeline(
    either(_Integer, _Float),
    predicate { |x| x.positive? },
  )
end

# matchers
matcher = Matcher.build do
  any(Integer, Float) & _.positive?
end
```
