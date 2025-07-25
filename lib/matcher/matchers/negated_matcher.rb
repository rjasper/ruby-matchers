# frozen_string_literal: true

module Matcher
  class NegatedMatcher < Base
    def initialize(matcher)
      super()

      @matcher = matcher
    end

    def ~
      @matcher
    end

    def check(state)
      state.errors << expected.namespace(:negated).not.valid(@matcher) if yield(@matcher).valid?
    end

    def to_s
      "neg(#{@matcher})"
    end
  end

  module MatcherBuilding
    def neg(matcher = UNDEFINED)
      return Pipe.new { neg(_1) } if Matcher.undefined?(matcher)

      ~Matcher.of(matcher)
    end
  end
end
