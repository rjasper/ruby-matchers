# Comparison: Schemacop

[Schemacop](https://github.com/sitrox/schemacop) is a DSL-based schema validator that can also generate
JSON Schema.

## String with enum

```ruby
# Schemacop
schema = Schemacop::Schema3.new(:string, enum: ["foo", "bar"])

# matchers
matcher = Matcher.build do
  any("foo", "bar")
end
```

## Integer with constraints

```ruby
# Schemacop
schema = Schemacop::Schema3.new(:integer,
  minimum: 0, maximum: 100, multiple_of: 2)

# matchers
matcher = Matcher.build do
  of(Integer) & (0..100) & _.even?
end
```

## Hash with required and optional properties

```ruby
# Schemacop
schema = Schemacop::Schema3.new :hash do
  str! :name
  int? :age
end

# matchers
matcher = Matcher.build do
  {
    name: String,
    optional(:age) => Integer,
  }
end
```

## Array of typed items

```ruby
# Schemacop
schema = Schemacop::Schema3.new :array do
  list :integer, minimum: 1, maximum: 5
end

# matchers
matcher = Matcher.build do
  each(of(Integer) & (1..5))
end
```

## Nested hash with array

```ruby
# Schemacop
schema = Schemacop::Schema3.new :hash do
  str! :title
  ary! :tags do
    list :string
  end
end

# matchers
matcher = Matcher.build do
  {
    title: String,
    tags: each(String),
  }
end
```
