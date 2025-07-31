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
        state.errors << e.message_for_errors
        return
      end

      state.errors[@expression] << yield(@matcher, result)
    end

    def to_s
      "project(#{@expression} => #{@matcher})"
    end
  end

  module MatcherBuilding
    def project(recorder = UNDEFINED, **projections)
      raise 'cannot mix project(expression) ^ matcher and project(expression => matcher)' if
        !Matcher.undefined?(recorder) && !projections.empty?

      return Pipe.new { project(recorder => _1) } unless Matcher.undefined?(recorder)

      project_matchers = projections.map do |r, m|
        expression = Recorder.to_expression(r)
        matcher = Matcher.of(m)

        ProjectMatcher.new(expression, matcher)
      end

      all(*project_matchers)
    end
  end
end
