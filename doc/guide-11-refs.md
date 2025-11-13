# Recursive Matchers

```ruby
m = Matcher.build do
  refs[:list] = {
    head: Integer,
    tail: optional(refs[:list]),
  }
end

m.match?({ head: 1, tail: { head: 2, tail: nil } })
# => true
m.match({ head: 1, tail: { head: "two", tail: nil } })
# > root[:tail][:head]: expected a kind of Integer but got "two"
```

## Allow cyclic references

```ruby
m = Matcher.build do
  refs[:vertex] = {
    name: String,
    edges: each(refs[:edge, cyclic: true]),
  }

  refs[:edge] = {
    weight: Integer,
    destination: refs[:vertex, cyclic: true],
  }

  { vertices: each(refs[:vertex]) }
end

a = { name: 'a', edges: [] }
b = { name: 'b', edges: [] }
c = { name: 'c', edges: [] }

a[:edges] << { weight: 1, destination: b }
b[:edges] << { weight: 2, destination: c }
c[:edges] << { weight: "3", destination: a }

graph = { vertices: [a, b, c] }

m.match(graph)
# > root[:vertices][0][:edges][0][:destination][:edges][0][:destination][:edges][0][:weight]: expected a kind of Integer but got "3"
# > root[:vertices][1]: actual has already failed before
# > root[:vertices][2]: actual has already failed before
```

## Disable cache

```ruby
m = Matcher.build do
  refs[:foo] = _ == vars[:a]

  [
    let(a: 1) ^ refs[:foo],
    let(a: 2) ^ refs[:foo],
  ]
end

# should only match [1, 2] but refs[:foo] caches result for 1 as valid:

m.match?([1, 1])
# => true, but shouldn't

# disable cache when matching result depends on other variables than actual:

m = Matcher.build do
  refs[:foo, { cache: false }] = _ == vars[:a]

  [
    let(a: 1) ^ refs[:foo],
    let(a: 2) ^ refs[:foo],
  ]
end

m.match([1, 1])
# > root[1]: expected actual == a but got 1 == 2
```

---

Next: [Custom Matchers](guide-12-custom-matchers.md)  
Previous: [Miscellaneous](guide-10-misc.md)
