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

    def check(state)
      begin
        result = @expression.evaluate(state.values)
      rescue CallError
        return
      end

      state.errors[@expression] << yield(@neg_matcher, result)
    end

    def to_s
      "~project(#{@expression} => #{@matcher})"
    end
  end
end
