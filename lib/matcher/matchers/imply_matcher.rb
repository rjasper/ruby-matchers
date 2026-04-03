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

  module MatcherDsl
    ##
    # Matches if condition mismatches or given matcher matches.
    # In other words, ignore +matcher+ unless +condition+ is met.
    # @example
    #   # matches "hello" and 42 but not "hi"
    #   imply(String, _.length <= 4)
    #   # alternatively:
    #   imply(String) ^ (_.length <= 4) # or
    #   of(String) >> (_.length <= 4)
    # @overload imply(condition, matcher)
    #   @param condition [Expression]
    #   @param matcher [Base]
    #   @return [ImplyMatcher]
    # @overload imply(condition)
    #   @param condition [Expression]
    #   @return [Chain<ImplyMatcher>]
    # @see Base#>>
    # @see #imply_one
    # @see #imply_any
    def imply(condition, matcher = UNDEFINED)
      return Chain.new { imply(condition, _1) } if Matcher.undefined?(matcher)

      condition = matcher_of(condition)
      matcher = matcher_of(matcher)

      ImplyMatcher.new(condition, matcher)
    end
  end
end
