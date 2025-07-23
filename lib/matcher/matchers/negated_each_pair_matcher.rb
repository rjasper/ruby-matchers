# frozen_string_literal: true

module Matcher
  class NegatedEachPairMatcher < Base
    def initialize(matcher, key: :key, value: :value, parent: :parent)
      super()

      @matcher = matcher
      @neg_matcher = ~matcher
      @key = key
      @value = value
      @parent = parent
    end

    def ~
      EachPairMatcher.new(@matcher, key: @key, value: @value, parent: @parent)
    end

    def check(state)
      actual = state.actual

      return unless actual.respond_to?(:each_pair)

      collector = state.new_collector.or!

      actual.each do |key, value|
        result = yield @neg_matcher, [key, value], @key => key, @value => value, @parent => actual

        return if result.valid?

        collector[key] << result
      end

      state.errors << collector.error
    end

    def to_s
      "~each_pair(#{@matcher})"
    end
  end
end
