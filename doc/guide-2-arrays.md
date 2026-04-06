# Match Arrays

Basic array matching:

```ruby
m = Matcher.build { [1, 2, 3] }

m.match?([1, 2, 3])   # => true
m.match([1, 2])       # > root: expected length of 3 but was 2
m.match([1, 2, 3, 4]) # > root: expected length of 3 but was 4

m.match([3, 2, 1])
# > root[0]: expected 1 but got 3
# > root[2]: expected 3 but got 1

m = Matcher.build { [Integer, String] }
m.match?([1, "foo"]) # => true
```

## Variables passed to element matchers

`ArrayMatcher` passes `index` and `parent` to its element matchers.

```ruby
# index or i
m = Matcher.build { [_ == i] }
m.match?([0]) # => true
m.match([1])  # > root[0]: expected actual == index but got 1 == 0

# parent
m = Matcher.build do
  in_order = imply(i > 0, parent[i - 1] <= _)
  [in_order, in_order, in_order]
end

m.match?([1, 2, 3])
# => true
m.match([1, 2, 0])
# root[2]: expected actual >= parent[index - 1] but got 0 >= 2, where parent = [1, 2, 0], index = 2
```

---

Next: [Hashes](guide-3-hashes.md)  
Previous: [Basics](guide-1-basics.md)
