# frozen_string_literal: true

module Matcher
  class NegatedProjectMatcher < Base
    def initialize(expression, matcher)
      super()

      @expression = expression
      @matcher = matcher
      @neg_matcher = ~matcher
    end

    def negated
      ProjectMatcher.new(@expression, @matcher)
    end

    def check(**)
      begin
        result = @expression.evaluate(**)
      rescue Call::Error
        return
      end

      errors[@expression] << @neg_matcher.match(**, actual: result)
    end

    def to_s
      "~project(#{@expression}, #{@matcher})"
    end
  end
end
