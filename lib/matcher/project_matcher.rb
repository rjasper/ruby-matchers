# frozen_string_literal: true

module Matcher
  class ProjectMatcher < Base
    def initialize(expression, matcher)
      super()

      @expression = expression
      @matcher = matcher
    end

    def check(**)
      result = @expression.evaluate(**)

      errors[@expression] << @matcher.match(**, actual: result)
    rescue Call::NotRespondingError => e
      errors << e.message_for_errors
    end

    def inspect
      "project(#{@expression.inspect}, #{@matcher.inspect})"
    end
  end
end
