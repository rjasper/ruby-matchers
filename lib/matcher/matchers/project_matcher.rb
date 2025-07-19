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
      rescue CallError => e
        # rescuing here instead of method so we won't catch from yield
        errors << e.message_for_errors
        return
      end

      errors[@expression] << yield(@matcher, result)
    end
    protected :check

    def to_s
      "project(#{@expression} => #{@matcher})"
    end
  end

  module MatcherBuilding
    def project(recorder = NULL, **projections)
      raise 'cannot mix project(expression) ^ matcher and project(expression => matcher)' if
        !Matcher.null?(recorder) && !projections.empty?

      return Pipe.new { project(recorder => _1) } unless Matcher.null?(recorder)

      project_matchers = projections.map do |r, m|
        expression = ExpressionRecorder.to_expression(r)
        matcher = Matcher.of(m)

        ProjectMatcher.new(expression, matcher)
      end

      all(*project_matchers)
    end
  end
end
