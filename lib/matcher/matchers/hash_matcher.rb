# frozen_string_literal: true

module Matcher
  ##
  # == Basic hash matching
  #
  #   m = Matcher.build do
  #     { foo: 1 }
  #   end
  #
  #   m.match?({ foo: 1 })
  #   # => true
  #   m.match({ foo: 0 })
  #   # > root[:foo]: expected 1 but got 0
  #   m.match({ foo: 1, bar: 1 })
  #   # > root[:bar]: did not expect to include key :bar but got {:foo=>1, :bar=>2}
  #
  #   # Use matchers for values
  #   m = Matcher.build { { foo: Integer } }
  #   m.match?({ foo: 2 }) # => true
  #
  # == Variables passed to value matchers
  #
  # HashMatcher passes +key+, +value+ and +parent+ to its value matchers.
  #
  #   # key
  #   m = Matcher.build { { foo: _ == k.to_s } }
  #   m.match?({ foo: "foo" })
  #   # => true
  #   m.match({ foo: "bar" })
  #   # > root[:foo]: expected actual == key.to_s but got "bar" == "foo", where k = :foo
  #
  #   # parent
  #   m = Matcher.build do
  #     {
  #       items: Array,
  #       length: equal(parent[:items].length),
  #     }
  #   end
  #
  #   m.match({ items: [1], length: 10 })
  #   # > root[:length]: expected 1 but got 10
  #
  # == Match hash partially
  #
  # Use +partial+ and +partial_r+ to match a hash only partially.
  #
  # == Optional keys
  #
  # Match value only if key included:
  #
  #   m = Matcher.build do
  #     { optional(:foo) => 1 }
  #   end
  #
  #   m.match?({})           # => true
  #   m.match?({ foo: 1 })   # => true
  #   m.match?({ foo: 2 })   # => false
  #   m.match?({ foo: nil }) # => false
  #
  # == Match remaining entries
  #
  #   m = Matcher.build do
  #     {
  #       id: Integer,
  #       others => each_value(String),
  #     }
  #   end
  #
  #   m.match?({ id: 1, foo: "bar" })
  #   # => true
  #   m.match({ id: 1, foo: nil })
  #   # > root[:foo]: expected a kind of String but got nil
  #
  # == Expression keys
  #
  #   m = Matcher.build do
  #     { vars[:my_key] => 1 }
  #   end
  #
  #   m.match?({ foo: 1 }, my_key: :foo) # => true
  #
  # @see MatcherBuilding#partial
  # @see MatcherBuilding#partial_r
  # @see MatcherBuilding#each_pair
  # @see MatcherBuilding#each_key
  # @see MatcherBuilding#each_value
  class HashMatcher < Base
    def initialize(hash, partial: false, negated: false)
      super()

      @hash = negated ? hash.transform_values(&:~) : hash
      @original_hash = hash
      @partial = partial
      @negated = negated
      @includes_others = hash.include?(Others.instance)
      @includes_optionals = hash.each_key.any? { _1.is_a?(Optional) }
      @includes_expressions = hash.each_key.any? { _1.is_a?(Expression) }

      raise 'cannot use partial(others => ...)' if @partial && @includes_others
    end

    def negate
      HashMatcher.new(@original_hash, partial: @partial, negated: !@negated)
    end

    def validate(state, &)
      return validate_negated(state, &) if @negated

      actual = state.actual

      unless actual.is_a?(Hash)
        state.errors << state.expected.kind_of(Hash)
        return
      end

      if @includes_expressions
        expression_values = {}

        @hash.each_key.with_index do |key, i|
          key = key.value if key.is_a?(Optional)
          expression_values[i] = key.evaluate(state.values) if key.is_a?(Expression)
        end
      end

      expected_keys = if @includes_optionals || @includes_expressions
        @hash.keys.map.with_index do |k, i|
          k = k.value if k.is_a?(Optional)
          k = expression_values[i] if k.is_a?(Expression)
          k
        end
      else
        @hash.keys
      end

      extra_keys = actual.keys - expected_keys

      if !@partial && !@includes_others
        extra_keys.each do |key|
          state.errors[key] << state.expected.not.having_key(key)
        end
      end

      @hash.each_with_index do |(key, value), i|
        if key.is_a?(Others)
          state.errors << yield(value, actual.slice(*extra_keys))

          next
        end

        is_optional = key.is_a?(Optional)
        key = key.value if is_optional
        error_key = key
        key = expression_values[i] if key.is_a?(Expression)
        actual_value = actual[key]

        if actual_value.nil? && !actual.key?(key)
          state.errors << state.expected.having_key(key) unless is_optional
        else
          error = yield(value, actual_value, key:, parent: actual)

          next if error.valid?

          error_key = key_call_for(error_key) if error_key.is_a?(Expression)

          state.errors[error_key] << error
        end
      end
    end

    def to_s
      if @negated
        @partial ? "~partial(#{@original_hash})" : "neg(#{@original_hash})"
      else
        @partial ? "partial(#{@hash})" : @hash.to_s
      end
    end

    private

    def validate_negated(state)
      actual = state.actual

      return unless actual.is_a?(Hash)

      if @hash.empty?
        if @partial
          state.errors << state.report.kind_of(Hash)
        elsif actual.empty?
          state.errors << state.report.predicate(:empty?)
        end

        return
      end

      if @includes_expressions
        expression_values = {}

        @hash.each_key.with_index do |key, i|
          key = key.value if key.is_a?(Optional)
          expression_values[i] = key.evaluate(state.values) if key.is_a?(Expression)
        end
      end

      expected_keys = if @includes_optionals || @includes_expressions
        @hash.keys.map.with_index do |k, i|
          k = k.value if k.is_a?(Optional)
          k = expression_values[i] if k.is_a?(Expression)
          k
        end
      else
        @hash.keys
      end

      extra_keys = actual.keys - expected_keys

      return if !@partial && !@includes_others && !extra_keys.empty?

      collector = state.new_collector.or!

      @hash.each_with_index do |(key, value), i|
        if key.is_a?(Others)
          result = yield(value, actual.slice(*extra_keys))

          return if result.valid?

          collector << result

          next
        end

        is_optional = key.is_a?(Optional)
        key = key.value if is_optional
        error_key = key
        key = expression_values[i] if key.is_a?(Expression)
        actual_value = actual[key]

        if actual_value.nil? && !actual.key?(key)
          next if is_optional

          return
        end

        result = yield(value, actual_value, key:, parent: actual)

        return if result.valid?

        error_key = key_call_for(error_key) if error_key.is_a?(Expression)

        collector[error_key] << result
      end

      state.errors << if collector.empty?
        state.report.predicate(:empty?)
      else
        collector.error
      end
    end

    def key_call_for(key)
      Call.new(Variable.actual, :[], [key])
    end
  end

  module MatcherBuilding
    ##
    # Matches hash partially
    # @example
    #   # matches { foo: 1, bar: 2 } but not { foo: 0, bar: 2 }
    #   partial(foo: 1)
    # @param hash [Hash]
    # @return [HashMatcher]
    def partial(hash)
      hash = hash.to_h do |k, v|
        [expression_or_value(k), matcher_of(v)]
      end

      HashMatcher.new(hash, partial: true)
    end

    ##
    # Matches nested hashes partially
    # @example
    #   # matches { foo: { bar: 1, baz: 2 }, qux: 3 }
    #   partial_r(foo: { bar: 1 })
    #   # equivalent to:
    #   partial(foo: partial(bar: 1))
    # @param hash [Hash]
    # @return [HashMatcher]
    def partial_r(hash)
      hash = hash.to_h do |k, v|
        [expression_or_value(k), partial_r_helper(v)]
      end

      HashMatcher.new(hash, partial: true)
    end

    def partial_r_helper(value)
      if Recorder.recorder?(value) || !value.is_a?(Hash)
        matcher_of(value)
      else
        partial_r(value)
      end
    end
    private :partial_r_helper
  end
end
