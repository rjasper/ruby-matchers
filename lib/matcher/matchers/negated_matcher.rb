# frozen_string_literal: true

module Matcher
  class NegatedMatcher < Base
    def initialize(matcher)
      super()

      @matcher = matcher
    end

    def negated
      @matcher
    end

    def check(**)
      errors << "expected #{@matcher} to be invalid but got #{get_actual(**).inspect}" if @matcher.match(**).valid?
    end
    protected :check

    def inspect
      "neg(#{@matcher.inspect})"
    end
  end
end
