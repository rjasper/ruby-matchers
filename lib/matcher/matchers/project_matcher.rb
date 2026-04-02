# frozen_string_literal: true

module Matcher
  class ProjectMatcher < Base
    def initialize(expression, matcher)
      super()

      @expression = expression
      @matcher = matcher
    end

    def negate
      NegatedProjectMatcher.new(@expression, @matcher)
    end

    def validate(state)
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
    ##
    # Matches the value of an expression
    # @example
    #   # matches "5"
    #   project(_.to_i => _ < 10)
    #   # alternatively:
    #   project(_.to_i) ^ (_ < 10)
    #   # project multiple expressions
    #   project(
    #     _.foo => 1,
    #     _.bar => 2,
    #   )
    # @overload project(expression => matcher)
    #   @return [ProjectMatcher]
    # @overload project(expression)
    #   @return [Chain<ProjectMatcher>]
    # @overload project(**projections)
    #   @return [AllMatcher<ProjectMatcher>]
    def project(expression = UNDEFINED, **projections)
      raise "cannot mix project(expression) ^ matcher and project(expression => matcher)" if
        !Matcher.undefined?(expression) && !projections.empty?

      return Chain.new { project(expression => _1) } unless Matcher.undefined?(expression)

      project_matchers = projections.map do |e, m|
        e = expression_of(e)
        m = matcher_of(m)

        ProjectMatcher.new(e, m)
      end

      all(*project_matchers)
    end
  end
end
