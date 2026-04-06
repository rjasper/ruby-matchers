# Comparison: dry-schema / dry-validation

[dry-schema](https://dry-rb.org/gems/dry-schema/) and
[dry-validation](https://dry-rb.org/gems/dry-validation/) are a pair of gems
for validating params and business rules. They are commonly used in web
applications to validate request parameters.

## Basic hash with type checks

```ruby
# dry-schema
UserSchema = Dry::Schema.Params do
  required(:name).filled(:string)
  required(:email).filled(:string)
  required(:age).maybe(:integer)
end

# matchers
user_matcher = Matcher.build do
  {
    name: String,
    age: optional(Integer),
    email: String,
  }
end
```

## Nested hashes

```ruby
# dry-schema
schema = Dry::Schema.Params do
  required(:address).hash do
    required(:city).filled(:string, min_size?: 3)
    required(:street).filled(:string)
    required(:country).hash do
      required(:name).filled(:string)
      required(:code).filled(:string)
    end
  end
end

# matchers
matcher = Matcher.build do
  {
    address: {
      city: of(String) & (_.length >= 3),
      street: String,
      country: {
        name: String,
        code: String,
      },
    },
  }
end
```

## Array of hashes with constraints

```ruby
# dry-schema
schema = Dry::Schema.Params do
  required(:people).value(:array, min_size?: 1).each do
    hash do
      required(:name).filled(:string)
      required(:age).filled(:integer, gteq?: 18)
    end
  end
end

# matchers
matcher = Matcher.build do
  {
    people: of(Array) & !_.empty? & each({
      name: String,
      age: of(Integer) & (_ >= 18),
    }),
  }
end
```

## Built-in predicates

```ruby
# dry-schema — regex, ranges, inclusion, comparison
Dry::Schema.Params do
  required(:sample).value(format?: /^a/)
  required(:count).value(:integer, gteq?: 0, lteq?: 3)
  required(:role).value(included_in?: %w[admin user])
  required(:score).value(gt?: 0)
end

# matchers
matcher = Matcher.build do
  {
    sample: /^a/,
    count: 0..3,
    role: any("admin", "user"),
    score: _ > 0,
  }
end
```

## Optional and nullable

```ruby
# dry-schema
Dry::Schema.Params do
  optional(:nickname).filled(:string)
  required(:middle_name).maybe(:string)
end

# matchers
matcher = Matcher.build do
  {
    optional(:nickname) => String,
    middle_name: optional(String),
  }
end
```

## Cross-field validation (dry-validation)

```ruby
# dry-validation
class EventContract < Dry::Validation::Contract
  params do
    required(:start_date).value(:date)
    required(:end_date).value(:date)
  end

  rule(:end_date, :start_date) do
    key.failure('must be after start date') if values[:end_date] < values[:start_date]
  end
end

# matchers
matcher = Matcher.build do
  of({
    start_date: Date,
    end_date: Date,
  }) & (_[:end_date] > _[:start_date])
end
```
