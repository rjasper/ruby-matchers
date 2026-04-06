# Comparison with Other Gems

These documents show how common validation tasks look in other Ruby gems
compared to matchers. Each page takes real examples from another gem's
documentation and shows an equivalent using matchers.

- [dry-schema / dry-validation](comparison/dry-schema.md) — params and
  business rule validation, commonly used in web applications
- [RSpec Composable Matchers](comparison/rspec.md) — built-in composable
  matchers for test assertions
- [Classy Hash](comparison/classy_hash.md) — lightweight hash validation using
  Ruby classes, ranges, regexps, and lambdas
- [RSchema](comparison/rschema.md) — composable schema validation with a Ruby
  DSL
- [HashValidator](comparison/hash_validator.md) — string-based type names with
  nested hash support
- [json_schemer](comparison/json_schemer.md) — JSON Schema validation in Ruby
- [Schemacop](comparison/schemacop.md) — DSL-based schema validator with JSON
  Schema generation

## Feature overview

| Feature                   | matchers              | dry-schema         | RSpec match         | Classy Hash      | RSchema          |
|---------------------------|-----------------------|--------------------|---------------------|------------------|------------------|
| Type checks               | `String`              | `filled(:string)`  | `an_instance_of`    | `String`         | `_String`        |
| Ranges                    | `1..10`               | `size?: 0..3`      | `a_value < 3`       | `1..10`          | —                |
| Regex                     | `/pat/`               | `format?: /pat/`   | `a_string_matching` | `/pat/`          | —                |
| Optional key              | `optional(:k) => ...` | `optional(:k)`     | —                   | `[:optional, T]` | `optional(:k)`   |
| Nullable                  | `optional(T)`         | `maybe(:type)`     | —                   | `[NilClass, T]`  | `maybe(T)`       |
| Union types               | `any(A, B)`           | —                  | compound matchers   | `[A, B]`         | `either(A, B)`   |
| Negate                    | `~matcher`            | —                  | —                   | —                | —                |
| Implication               | `A >> B`              | custom rule        | —                   | —                | —                |
| Nested hashes             | `{ a: { b: T } }`     | `hash do ... end`  | `match(a: ...)`     | `{ a: { b: T }}` | `define_hash`    |
| Array items               | `each(T)`             | `.each do ... end` | `all(matcher)`      | `[[T]]`          | `array(T)`       |
| Partial hash              | `partial(k: v)`       | —                  | `include(k: v)`     | default          | —                |
| Strict hash               | default               | default            | `match(...)`        | `strict: true`   | default          |
| Recursive structures      | `refs[:name]`         | —                  | —                   | —                | —                |
| Error paths               | `root[:a][0][:b]`     | `[:a, 0, :b]`      | diff output         | `:key`           | `{0 => {:k =>}}` |
| Errors through transforms | yes (map, filter)     | —                  | —                   | —                | —                |
| Expressions as matchers   | `_ >= 18`             | `gteq?: 18`        | `a_value >= 18`     | lambda           | `predicate`      |
| Auto error messages       | from expression       | predicate name     | matcher desc        | lambda return    | symbolic name    |
| Cross-field validation    | `let` + `vars`        | custom rules       | —                   | —                | —                |
| String parsing            | `parse_integer`, etc. | via dry-types      | —                   | —                | —                |
