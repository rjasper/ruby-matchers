# frozen_string_literal: true

module Matcher
  class EachMatcher < Base
    def initialize(matcher)
      super()

      @matcher = matcher
    end

    def negate
      NegatedEachMatcher.new(@matcher)
    end

    def check(state)
      unless state.actual.respond_to?(:each)
        state.errors << state.expected.responding_to(:each)
        return
      end

      i = 0
      state.actual.each do |item|
        state.errors[i] << yield(@matcher, item, index: i, parent: state.actual)
        i += 1
      end
    end

    def to_s
      "each(#{@matcher})"
    end
  end

  module MatcherBuilding
    def each(matcher = UNDEFINED)
      return Pipe.new { each(_1) } if Matcher.undefined?(matcher)

      EachMatcher.new(matcher_of(matcher))
    end
  end
end
