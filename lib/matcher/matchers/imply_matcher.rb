# frozen_string_literal: true

module Matcher
  class ImplyMatcher < Base
    attr_reader :condition, :matcher

    def initialize(condition, matcher, negated: false)
      super()

      @condition = condition
      @matcher = negated ? ~matcher : matcher
      @original_matcher = matcher
      @negated = negated
    end

    def negate
      ImplyMatcher.new(@condition, @original_matcher, negated: !@negated)
    end

    def validate(state, &)
      return validate_negated(state, &) if @negated

      if @condition.is_a?(ExpressionMatcher)
        begin
          # evaluate expression directly
          return unless @condition.expression.evaluate(state.values)
        rescue CallError
          return
        end
      else
        return unless yield(@condition).valid?
      end

      state.errors << yield(@matcher)
    end

    def to_s
      "#{'~' if @negated}imply(#{@condition}, #{@original_matcher})"
    end

    private

    def validate_negated(state)
      condition_errors = yield @condition

      state.errors << if condition_errors.valid?
        yield(@matcher)
      else
        condition_errors
      end
    end
  end

  module MatcherBuilding
    def imply(condition, matcher = UNDEFINED)
      return Pipe.new { imply(condition, _1) } if Matcher.undefined?(matcher)

      condition = matcher_of(condition)
      matcher = matcher_of(matcher)

      ImplyMatcher.new(condition, matcher)
    end
  end
end
