# Comparison: HashValidator

[HashValidator](https://github.com/jamesbrooks/hash_validator) uses string type names and supports nested hashes, regexps,
and lambdas.

## Basic types

```ruby
# HashValidator
validations = { name: "string", active: "boolean", tags: "array" }
HashValidator.validate(hash, validations)

# matchers
matcher = Matcher.build do
  { name: String, active: boolean, tags: Array }
end
```

## Nested hash

```ruby
# HashValidator
validations = {
  user: {
    first_name: "string",
    age: "integer",
  },
}

# matchers
matcher = Matcher.build do
  {
    user: {
      first_name: String,
      age: Integer,
    },
  }
end
```

## Enum

```ruby
# HashValidator
validations = { status: ["active", "inactive", "pending"] }

# matchers
matcher = Matcher.build do
  { status: any("active", "inactive", "pending") }
end
```

## Lambda validation

```ruby
# HashValidator
validations = {
  age: ->(value) { value.is_a?(Integer) && value >= 18 },
}

# matchers
matcher = Matcher.build do
  { age: of(Integer) & (_ >= 18) }
end
```
