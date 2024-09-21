# frozen_string_literal: true

module Matcher
  class ProjectMatcher < Base
    def initialize(expression, matcher)
      super()

      @expression = expression
      @matcher = matcher
    end

    def check(**)
      begin
        result = @expression.evaluate(**)
      rescue Call::NotRespondingError => e
        errors << e.message_for_errors
        return
      end

      errors[@expression] << @matcher.match(**, actual: result)
    end

    def inspect
      "project(#{@expression.inspect}, #{@matcher.inspect})"
    end
  end
end
