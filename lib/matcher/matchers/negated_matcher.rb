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

    def validate(state)
      return unless yield(@matcher).valid?

      state.errors << state.expected.namespace(:negated).not.valid(@matcher)
    end

    def to_s
      "neg(#{@matcher})"
    end
  end
end
