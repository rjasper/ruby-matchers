# frozen_string_literal: true

module Matcher
  ##
  # Match hash keys.
  # @example
  #   m = Matcher.build { keys(:foo, :bar) }
  #
  #   m.match?({ foo: 1, bar: 2 })
  #   # => true
  #   m.match({ foo: 1, qux: 3 })
  #   # > root: expected to include key :bar but got {:foo=>1, :qux=>3}
  #   # > root: did not expect to include key :qux but got {:foo=>1, :qux=>3}
  class KeysMatcher < Base
    def initialize(keys, partial: false, negated: false)
      super()

      @keys = keys
      @partial = partial
      @negated = negated
      @includes_expressions = keys.any? { _1.is_a?(Expression) }
    end

    def negate
      KeysMatcher.new(@keys, partial: @partial, negated: !@negated)
    end

    def validate(state, &)
      return validate_negated(state, &) if @negated

      actual = state.actual

      unless actual.is_a?(Hash)
        state.errors << state.expected.kind_of(Hash)
        return
      end

      actual_keys = actual.keys

      expected_keys = if @includes_expressions
        @keys.map { _1.is_a?(Expression) ? _1.evaluate(state.values) : _1 }
      else
        @keys
      end

      (expected_keys - actual_keys).each do |key|
        state.errors << state.expected.having_key(key)
      end

      return if @partial

      (actual_keys - expected_keys).each do |key|
        state.errors << state.expected.not.having_key(key)
      end
    end

    def to_s
      helper = @partial ? 'partial_keys' : 'keys'
      args = @keys.map(&:inspect).join(', ')

      "#{'~' if @negated}#{helper}(#{args})"
    end

    private

    def validate_negated(state)
      actual = state.actual

      return unless actual.is_a?(Hash)

      actual_keys = actual.keys

      expected_keys = if @includes_expressions
        @keys.map { _1.is_a?(Expression) ? _1.evaluate(state.values) : _1 }
      else
        @keys
      end

      if @partial
        return unless (expected_keys - actual_keys).empty?

        state.errors.or!

        (actual_keys & expected_keys).each do |key|
          state.errors << state.expected.not.having_key(key)
        end
      else
        return if actual_keys != expected_keys

        state.errors.or!

        actual_keys.each do |key|
          state.errors << state.expected.not.having_key(key)
        end
      end
    end
  end

  module MatcherBuilding
    ##
    # Matches all keys of a hash
    # @example
    #   # matches { foo: 1, bar: 2 } but not { foo: 1, qux: 3 }
    #   keys(:foo, :bar)
    #   # using key expression, matches { "the_key" => 23 }
    #   let(my_key: :the_key) ^ keys(vars[:my_key].to_s)
    # @param keys [Array] supports expressions
    # @param partial [true, false] ignores extra keys when +true+
    # @return [KeysMatcher]
    # @see #partial_keys
    def keys(*keys, partial: false)
      keys.each_with_index do |key, i|
        keys[i] = expression_or_value(key)
      end

      KeysMatcher.new(keys, partial:)
    end

    ##
    # Matches hash if all given keys are included. Ignores extra keys.
    # @example
    #   # matches { foo: 1, bar: 2 } but not { bar: 2 }
    #   partial_keys(:foo)
    # @param keys [Array] supports expressions
    # @return [KeysMatcher]
    # @see #keys
    def partial_keys(*keys)
      keys(*keys, partial: true)
    end
  end
end
