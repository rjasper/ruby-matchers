# Implement your own matcher

Sometimes your matching criteria cannot be easily expressed as a single
expression, or you need more control over error generation. In those cases you
may implement your own matcher.

Below is an example for a reusable `DistinctMatcher`.

```ruby
# This matcher checks if an collection contains only distinct elements.
# [1, 2, 3] is distinct while [1, 2, 1] is not.
class DistinctMatcher < Matcher::Base
  def validate(state)
    # +state+ gives you access to the current matching context.
    # 
    # Its most important methods are:
    # - +state.actual+
    # - +state.errors+
    # - +state.expected+ or +state.report+

    # Before we check for distinctness we assert all implicit prerequisites.
    # Your matcher should never fail, regardless of what +actual+ actually is.
    # If actual is something unexpected, don't raise anything but add an error
    # instead.
    unless state.actual.respond_to?(:each)
      # +state.errors+ is an error collector.
      # +state.expected+ is a message builder.
      # +responding_to+ builds a standard :responding_to message
      state.errors << state.expected.responding_to(:each)

      # Since we've failed your implicit prerequisite we can't check for
      # distinctness and stop.
      return
    end

    # We use indices to save where we encountered an element the first time.
    indices = Hash.new

    # We are not using each_with_index or each.with_index because we have only
    # asserted respond_to?(:each).
    i = 0
    state.actual.each do |e|
      if (original_index = indices[e])
        # With [i] we express where our error occurred at. Here +i+ is an
        # Integer, but it could be any Expression. In this case +i+ will be
        # converted to the expression +actual[i]+ which means the message's
        # subject is whatever +actual[i]+ returns.
        state.errors[i] << state.expected.not.duplicate(original_index)
      else
        indices[e] = i
      end

      i += 1
    end
  end
end

# Define `distinct` helper for convenient usage inside Matcher.build { ... }.
module Matcher::MatcherBuilding
  def distinct
    DistinctMatcher.new
  end
end
```

For simple ad-hoc matchers you can use `inline` instead.

## inline

The inline helper allows you to write a matcher in a similar way to writing your
own matcher class. However, it saves you from creating a new file for a simple
one-time-use matcher:

```ruby
Matcher.build do
  # matches array with distinct values like [1, 2, 3] but not [1, 1, 1]
  distinct = inline do
    # Compared to the matcher class example above we are more lax, because
    # this is "just" an inline matcher, and we check that actual is an Array
    # outside the inline matcher.
    
    indices = Hash.new
    
    actual.each_with_index do |e, i|
      if (original_index = indices[e])
        errors[i] << expected.not.duplicate(original_index)
      else
        indices[e] = i
      end
    end
  end
  
  of(Array) & distinct
end
```

---

Previous: [Recursive Matchers](guide-11-refs.md)
