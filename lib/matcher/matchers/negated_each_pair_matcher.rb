# frozen_string_literal: true

module Matcher
  class NegatedEachPairMatcher < Base
    def initialize(matcher)
      super()

      @matcher = matcher
      @neg_matcher = ~matcher
    end

    def negate
      EachPairMatcher.new(@matcher)
    end

    def validate(state)
      actual = state.actual

      return unless actual.respond_to?(:each_pair)

      collector = state.new_collector.or!

      actual.each do |key, value|
        result = yield(@neg_matcher, [key, value], key:, value:, parent: actual)

        return nil if result.valid?

        collector[key] << result
      end

      state.errors << collector.error
    end

    def to_s
      "~each_pair(#{@matcher})"
    end
  end
end
