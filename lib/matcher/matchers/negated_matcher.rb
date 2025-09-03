# frozen_string_literal: true

module Matcher
  class NegatedMatcher < Base
    def initialize(matcher)
      super()

      @matcher = matcher
    end

    def negate
      @matcher
    end

    def check(state)
      state.errors << state.expected.namespace(:negated).not.valid(@matcher) if yield(@matcher).valid?
    end

    def to_s
      "neg(#{@matcher})"
    end
  end
end
