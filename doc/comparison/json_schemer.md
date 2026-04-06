# Comparison: json_schemer

[json_schemer](https://github.com/davishmcclurg/json_schemer) implements JSON
Schema validation in Ruby.

## Basic type and constraint

```ruby
# json_schemer
schema = {
  "type" => "object",
  "properties" => {
    "abc" => { "type" => "integer", "minimum" => 11 },
  },
}
schemer = JSONSchemer.schema(schema)
schemer.valid?({ "abc" => 11 })

# matchers
matcher = Matcher.build do
  { "abc" => of(Integer) & (_ >= 11) }
end
matcher.match?({ "abc" => 11 })
```

## Nested object with array

```ruby
# json_schemer
schema = {
  "type" => "object",
  "required" => ["name", "tags"],
  "properties" => {
    "name" => { "type" => "string", "minLength" => 1 },
    "tags" => {
      "type" => "array",
      "items" => { "type" => "string" },
      "minItems" => 1,
    },
  },
}

# matchers
matcher = Matcher.build do
  {
    "name" => of(String) & !_.empty?,
    "tags" => of(Array) & !_.empty? & each(String),
  }
end
```

## allOf / anyOf / oneOf composition

```ruby
# json_schemer — allOf
schema = {
  "allOf" => [
    { "type" => "integer" },
    { "minimum" => 11 },
  ],
}

# matchers
matcher = Matcher.build do
  of(Integer) & (_ >= 11)
end

# json_schemer — anyOf
schema = {
  "anyOf" => [
    { "type" => "string" },
    { "type" => "integer" },
  ],
}

# matchers
matcher = Matcher.build do
  any(String, Integer)
end
```
