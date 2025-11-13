# Quick Reference

## Basic

| Helper              | Description               | Alternative        | Example                  |
|---------------------|---------------------------|--------------------|--------------------------|
| `of(object)`        | Convert object to matcher |                    | `of(String)`             |
| `equal(value)`      | Match equal value         |                    | `equal(String)`          |
| `boolean`           | Match `true` or `false`   |                    | `{ available: boolean }` |
| `optional(matcher)` | Match nil or value        | optional ^ matcher | `optional(String)`       |
| `present(matcher)`  | Match value but not nil   |                    | `present(my_local)`      |

## Combine Matchers

| Helper                        | Description                     | Alternative | Example                             |
|-------------------------------|---------------------------------|-------------|-------------------------------------|
| `neg(matcher)`                | Negate matcher                  | `~matcher`  | `neg(1)` or `~equal(1)`             |
| `all(*matchers)`              | Match every matcher             | `a * b`     | `all(_ > 10, _.even?)`              |
| `lazy_all(*matchers)`         | Match every, return last error  | `a & b`     | `lazy_all(Integer, _.positive?)`    |
| `any(*matchers)`              | Match at least one              | `a + b`     | `any(String, Integer)`              |
| `lazy_any(*matchers)`         | Match at least one, return last | `a \| b`    | `lazy_any(String, Integer)`         |
| `one(*matchers)`              | Match exactly one               |             | `one(_.include?(1), _.include?(2))` |
| `imply(condition, matcher)`   | Match only for condition        | `a >> b`    | `each(Integer) >> (_.sum < 10)`     |
| `imply_one(*matchers, else:)` | Exactly one implied             |             |                                     |
| `imply_any(*matchers, else:)` | At least one implied            |             |                                     |
| `always`                      | Always matches                  |             | `{ foo: always }`                   |
| `never`                       | Never matches                   |             |                                     |

## Arrays and other enumerables

| Helper                    | Description                       | Alternative                | Example                       |
|---------------------------|-----------------------------------|----------------------------|-------------------------------|
| `each(matcher)`           | Match each item                   | `each ^ matcher`           | `each(Integer)`               |
| `equal_set(*items)`       | Match like a set                  |                            | `equal_set(1, 2, 3)`          |
| `map(expr, matcher)`      | Map items before matching         | `map(expr) ^ matcher`      | `map(_.to_i, [1, 2])`         |
| `filter(expr, matcher)`   | Match filtered elements           | `filter(expr) ^ matcher`   | `filter(_.odd?, [1, 3, 5])`   |
| `index_by(expr, matcher)` | Index array into hash, then match | `index_by(expr) ^ matcher` | `index_by(_[:name], { ... })` |

## Hashes

| Helper                | Description                    | Alternative            | Example                            |
|-----------------------|--------------------------------|------------------------|------------------------------------|
| `partial(hash)`       | Match hash partially           |                        | `partial(foo: 1)`                  |
| `partial_r(hash)`     | Match nested hashes partially  |                        | `partial_r(foo: { bar: 1 })`       |
| `others`              | Match remaining entries        |                        | `{ others => each_value(String) }` |
| `each_pair(matcher)`  | Match each entry               | `each_pair ^ matcher`  | `each_pair(k.to_s == v)`           |
| `each_key(matcher)`   | Match each key                 | `each_key ^ matcher`   | `each_key(Symbol)`                 |
| `each_value(matcher)` | Match each value               | `each_value ^ matcher` | `each_value(String)`               |
| `keys(*keys)`         | Match all keys                 |                        | `keys(:foo, :bar)`                 |
| `partial_keys(*keys)` | Match given keys, ignore extra |                        | `partial_keys(:foo)`               |
| `optional`            | Mark hash key as optional      |                        | `{ optional(:foo) => 1 }`          |

## Projections

| Helper                         | Description                 | Alternative                     | Example                     |
|--------------------------------|-----------------------------|---------------------------------|-----------------------------|
| `project(expr => matcher)`     | Match expression values     | `project(expr) ^ matcher`       | `project(_.to_i => _ < 10)` |
| `dig(*path, matcher)`          | Match deeply nested value   | `dig(*path) ^ matcher`          | `dig(1, :a) ^ Integer`      |
| `optional_dig(*path, matcher)` | Match nested if path exists | `optional_dig(*path) ^ matcher` | `optional_dig(:a, :b) ^ 1`  |

## Strings

| Helper                          | Description                   | Alternative                      | Example                                |
|---------------------------------|-------------------------------|----------------------------------|----------------------------------------|
| `regexp(pattern, matcher)`      | Match regexp, pass MatchData  | `regexp(pattern) ^ matcher`      | `regexp(/x=(\d+)/, _ < 10)`            |
| `parse_integer(matcher, base:)` | Parse integer and match       | `parse_integer(base:) ^ matcher` | `parse_integer(_.odd?)`                |
| `integer_format(base:)`         | Match valid integer string    |                                  | `{ id: integer_format }`               |
| `parse_float(matcher)`          | Parse float and match         | `parse_float ^ matcher`          | `parse_float(_ > 0.0)`                 |
| `float_format`                  | Match valid float string      |                                  | `{ price: float_format }`              |
| `parse_iso8601(matcher)`        | Parse ISO 8601 time and match | `parse_iso8601 ^ matcher`        | `parse_iso8601(_ < expr { Time.now })` |
| `iso8601_format`                | Match valid ISO 8601 string   |                                  | `{ at: iso8601_format }`               |
| `parse_json(matcher, **)`       | Parse JSON and match          | `parse_json(**) ^ matcher`       | `parse_json({ "foo" => Integer })`     |
| `json_format`                   | Match valid JSON string       |                                  | `{ body: json_format }`                |

## Other Matchers

| Helper                          | Description               | Alternative                | Example                                    |
|---------------------------------|---------------------------|----------------------------|--------------------------------------------|
| `let(assigns, matcher)`         | Set variables for matcher | `let(**assigns) ^ matcher` | `let(a: 1) ^ (_ == vars[:a])`              |
| `inline { ... }`                | Anonymous custom matcher  |                            | `inline { errors << ... }`                 |
| `raises(expr, matcher)`         | Match raised error        | `raises(expr) ^ matcher`   | `raises(_.fetch(:foo), KeyError)`          |
| `raises(matcher) { \|x\| ... }` | Block form                |                            | `raises(KeyError) { \|x\| x.fetch(:foo) }` |

## Miscellaneous

| Helper           | Description                   | Alternative | Example                                               |
|------------------|-------------------------------|-------------|-------------------------------------------------------|
| `chain(*chains)` | Reduce multiple chains to one | `a ^ b ^ c` | `chain(let(a: 1), filter(_.even?), _ < vars[:limit])` |
| `refs`           | Recursive matcher references  |             | `refs[:list] = { head: always, tail: refs[:list] }`   |
| `outside`        | Access enclosing scope        |             | `outside { @ivar }`                                   |

## Expression Building

| Helper                         | Description                  | Alias | Example                            |
|--------------------------------|------------------------------|-------|------------------------------------|
| `actual`                       | Actual value being matched   | `_`   | `_ > 10`, `_.even?`                |
| `key`                          | Current hash key             | `k`   | `k.to_s == v`                      |
| `value`                        | Current hash value           | `v`   | `each_pair(k == v)`                |
| `index`                        | Current element index        | `i`   | `each(_ == i)`                     |
| `parent`                       | Parent collection            |       | `each(_ < parent.length)`          |
| `original`                     | Value before mapping         |       | available in `map`                 |
| `vars`                         | Access named variables       |       | `vars[:my_value]`                  |
| `expr(obj)`                    | Turn object into recorder    |       | `expr(Time).now`                   |
| `expr { ... }`                 | Turn block into expression   |       | `expr { \|x\| x ? 1 : 2 }`         |
| `range(from, to, exclude_end)` | Build range with expressions |       | `range(0, vars[:limit])`           |
| `concat(*parts)`               | Concatenate to string        |       | `concat('foo=', vars[:foo])`       |
| `kernel`                       | Recorder for Kernel methods  |       | `kernel.Integer(vars[:a])`         |
| `logical_operators { ... }`    | Use `&`/`\|` as `&&`/`\|\|`  | `lo`  | `lo { vars[:a] \| vars[:b] }`      |
| `pass_through_blocks { ... }`  | Pass blocks through to call  | `ptb` | `ptb { _.instance_exec { @foo } }` |
| `assign { ... }`               | Capture assignment calls     |       | `assign { _.foo = 1 }`             |
