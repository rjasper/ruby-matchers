# frozen_string_literal: true

module Matcher
  class KeysMatcher < Base
    def initialize(keys, partial: false, negated: false)
      super()

      @keys = keys
      @partial = partial
      @negated = negated
      @includes_expressions = keys.any? { _1.is_a?(Expression) }
    end

    def ~
      KeysMatcher.new(@keys, partial: @partial, negated: !@negated)
    end

    def check(state, &)
      return negated_check(state, &) if @negated

      actual = state.actual

      unless actual.is_a?(Hash)
        state.errors << expected.kind_of(Hash)
        return
      end

      actual_keys = actual.keys

      expected_keys = if @includes_expressions
        @keys.map { _1.is_a?(Expression) ? _1.evaluate(state.values) : _1 }
      else
        @keys
      end

      (expected_keys - actual_keys).each do |key|
        state.errors << expected.having_key(key)
      end

      return if @partial

      (actual_keys - expected_keys).each do |key|
        state.errors << expected.not.having_key(key)
      end
    end

    def to_s
      helper = @partial ? 'partial_keys' : 'keys'
      args = @keys.map(&:inspect).join(', ')

      "#{'~' if @negated}#{helper}(#{args})"
    end

    private

    def negated_check(state)
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
          state.errors << expected.not.having_key(key)
        end
      else
        return if actual_keys != expected_keys

        state.errors.or!

        actual_keys.each do |key|
          state.errors << expected.not.having_key(key)
        end
      end
    end
  end

  module MatcherBuilding
    def keys(*keys, partial: false)
      keys.each_with_index do |key, i|
        keys[i] = Recorder.to_expression(key) if Recorder.recorder?(key)
      end

      KeysMatcher.new(keys, partial:)
    end

    def partial_keys(*)
      keys(*, partial: true)
    end
  end
end
