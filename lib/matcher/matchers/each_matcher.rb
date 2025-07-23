# frozen_string_literal: true

module Matcher
  class EachMatcher < Base
    def initialize(matcher, index: :index, parent: :parent)
      super()

      @matcher = matcher
      @index = index
      @parent = parent
    end

    def ~
      NegatedEachMatcher.new(@matcher, index: @index, parent: @parent)
    end

    def check(state)
      unless state.actual.respond_to?(:each)
        state.errors << expected.responding_to(:each)
        return
      end

      i = 0
      state.actual.each do |item|
        state.errors[i] << yield(@matcher, item, @index => i, @parent => state.actual)
        i += 1
      end
    end

    def to_s
      "each(#{@matcher})"
    end
  end

  module MatcherBuilding
    def each(matcher = NULL)
      return Pipe.new { each(_1) } if Matcher.null?(matcher)

      EachMatcher.new(Matcher.of(matcher))
    end
  end
end
