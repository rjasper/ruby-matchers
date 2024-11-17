# frozen_string_literal: true

module Matcher
  class ProjectMatcher < Base
    def initialize(expression, matcher)
      super()

      @expression = expression
      @matcher = matcher
    end

    def ~
      NegatedProjectMatcher.new(@expression, @matcher)
    end

    def check(actual)
      begin
        result = @expression.evaluate(values.merge(actual:))
      rescue Call::Error => e
        errors << e.message_for_errors
        return
      end

      errors[@expression] << yield(@matcher, result)
    end

    def to_s
      "project(#{@expression}, #{@matcher})"
    end
  end

  module MatcherBuilding
    def project(recorder, matcher = NULL)
      return Pipe.new { project(recorder, _1) } if Matcher.null?(matcher)

      expression = ExpressionRecorder.to_expression(recorder)
      matcher = Matcher.of(matcher)

      ProjectMatcher.new(expression, matcher)
    end
  end
end
