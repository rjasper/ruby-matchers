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

    def check(state)
      begin
        result = @expression.evaluate(state.values)
      rescue CallError => e
        # rescuing here instead of method so we won't catch from yield
        state.errors << e.message_for_errors(state.actual)
        return
      end

      state.errors[@expression] << yield(@matcher, result)
    end

    def to_s
      "project(#{@expression} => #{@matcher})"
    end
  end

  module MatcherBuilding
    def project(expression = UNDEFINED, **projections)
      raise 'cannot mix project(expression) ^ matcher and project(expression => matcher)' if
        !Matcher.undefined?(expression) && !projections.empty?

      return Pipe.new { project(expression => _1) } unless Matcher.undefined?(expression)

      project_matchers = projections.map do |e, m|
        e = Expression.of(e)
        m = Matcher.of(m)

        ProjectMatcher.new(e, m)
      end

      all(*project_matchers)
    end
  end
end
