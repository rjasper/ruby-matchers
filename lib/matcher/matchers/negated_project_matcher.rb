# frozen_string_literal: true

module Matcher
  class NegatedProjectMatcher < Base
    def initialize(expression, matcher)
      super()

      @expression = expression
      @matcher = matcher
      @neg_matcher = ~matcher
    end

    def ~
      ProjectMatcher.new(@expression, @matcher)
    end

    def check(actual)
      begin
        result = @expression.evaluate(values.merge(actual:))
      rescue CallError
        return
      end

      errors[@expression] << yield(@neg_matcher, result)
    end
    protected :check

    def to_s
      "~project(#{@expression} => #{@matcher})"
    end
  end
end
