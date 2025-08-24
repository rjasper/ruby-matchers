# frozen_string_literal: true

module Matcher
  class RaisesMatcher < Base
    def initialize(expression, matcher, negated: false)
      super()

      @expression = expression
      @matcher = negated ? ~matcher : matcher
      @original_matcher = matcher
      @negated = negated
    end

    def ~
      RaisesMatcher.new(@expression, @original_matcher, negated: !@negated)
    end

    def check(state)
      @expression.evaluate(state.values)

      return if @negated

      given = @expression.given_for(state.values)
      state.errors << expected.namespace(:expression).raising(@expression, StandardError, given)
    rescue StandardError => e
      state.errors[rescue_last_error] << yield(@matcher, unwrap_exception(e))
    end

    def to_s
      "#{'~' if @negated}raises(#{@expression}, #{@original_matcher})"
    end

    private

    def rescue_last_error
      @rescue_last_error ||= RescueLastErrorExpression.new(@expression)
    end

    def unwrap_exception(e)
      case e
      when CallError
        e.cause
      else
        e
      end
    end
  end

  module MatcherBuilding
    def raises(expression_or_matcher = UNDEFINED, matcher = UNDEFINED, &block)
      no_arg1 = Matcher.undefined?(expression_or_matcher)
      no_arg2 = Matcher.undefined?(matcher)

      if no_arg1 == no_arg2 && no_arg1 ^ block_given?
        raise ArgumentError, 'both expression and block given' unless no_arg1

        raise ArgumentError, 'neither expression nor block given'
      end

      if block_given?
        expression = ProcExpression.new(block)
        matcher = expression_or_matcher
      else
        expression = Expression.of(expression_or_matcher)
      end

      return Pipe.new { raises(expression, _1) } if
        Matcher.undefined?(matcher)

      matcher = Matcher.of(matcher)

      RaisesMatcher.new(expression, matcher)
    end
  end
end
