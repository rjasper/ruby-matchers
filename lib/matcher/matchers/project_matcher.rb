# frozen_string_literal: true

module Matcher
  class ProjectMatcher < Base
    def initialize(expression, matcher, negated: false)
      super()

      @expression = expression
      @matcher = negated ? ~matcher : matcher
      @original_matcher = matcher
      @negated = negated
    end

    def negate
      ProjectMatcher.new(@expression, @original_matcher, negated: !@negated)
    end

    def validate(state, &)
      return validate_negated(state, &) if @negated

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
      "#{"~" if @negated}project(#{@expression} => #{@original_matcher})"
    end

    private

    def validate_negated(state)
      begin
        result = @expression.evaluate(state.values)
      rescue CallError
        return
      end

      state.errors[@expression] << yield(@matcher, result)
    end
  end

  module MatcherDsl
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
      if !Matcher.undefined?(expression) && !projections.empty?
        raise "cannot mix project(expression) ^ matcher and " \
          "project(expression => matcher)"
      end

      unless Matcher.undefined?(expression)
        return Chain.new { project(expression => _1) }
      end

      project_matchers = projections.map do |e, m|
        e = expression_of(e)
        m = matcher_of(m)

        ProjectMatcher.new(e, m)
      end

      all(*project_matchers)
    end
  end
end
