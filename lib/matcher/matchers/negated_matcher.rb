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

    def check(actual)
      errors << "expected #{@matcher} to be invalid but got #{actual.inspect}" if yield(@matcher).valid?
    end
    protected :check

    def to_s
      "neg(#{@matcher})"
    end
  end
end
