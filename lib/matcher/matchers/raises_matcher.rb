# frozen_string_literal: true

module Matcher
  class RaisesMatcher < Base
    def initialize(
      expression,
      matcher,
      negated: false,
      rescue_exception: StandardError
    )
      super()

      @expression = expression
      @matcher = negated ? ~matcher : matcher
      @original_matcher = matcher
      @negated = negated
      @rescue_exception = rescue_exception
    end

    def negate
      RaisesMatcher.new(
        @expression,
        @original_matcher,
        negated: !@negated,
        rescue_exception: @rescue_exception,
      )
    end

    def validate(state)
      @expression.evaluate(state.values)

      return if @negated

      given = @expression.given_for(state.values)
      state.errors << state.expected.namespace(:expression)
        .raising(@expression, @rescue_exception, given)
    rescue @rescue_exception => e
      state.errors[rescue_last_error] << yield(@matcher, unwrap_exception(e))
    end

    def to_s
      "#{'~' if @negated}raises(#{@expression}, #{@original_matcher})"
    end

    private

    def rescue_last_error
      @rescue_last_error ||= RescueLastErrorExpression.new(@expression)
    end

    def unwrap_exception(error)
      case error
      when CallError
        error.cause
      else
        error
      end
    end
  end

  module MatcherBuilding
    ##
    # Matches raised error
    # @example
    #   # matches {} (because fetch raises KeyError)
    #   raises(_.fetch(:foo), KeyError)
    #   # alternatively:
    #   raises(_.fetch(:foo)) ^ KeyError
    #   # match error message
    #   raises(_.call, message: /something went wrong/)
    #   # pass block instead of expression
    #   raises(NoMethodError) { |x| x.fetch(:foo) }
    #   # rescue non-standard exceptions
    #   raises(_.call, rescue: Exception)
    # @overload raises(expression, matcher, message: UNDEFINED, rescue: StandardError)
    #   Matches error raised from expression.
    #   @param expression [Expression]
    #   @param matcher [Base] matcher for error
    #   @param message [Base] matcher for message
    #   @param rescue [Class] exception class to rescue
    #   @return [RaisesMatcher]
    # @overload raises(matcher, message: UNDEFINED, rescue: StandardError, &)
    #   Matches error raised from block.
    #   @param matcher [Base] matcher for error
    #   @param message [Base] matcher for message
    #   @param rescue [Class] exception class to rescue
    #   @yield actual
    #   @return [OptionalChain<RaisesMatcher>]
    def raises(
      expression_or_matcher = UNDEFINED,
      matcher = UNDEFINED,
      message: UNDEFINED,
      rescue: StandardError,
      &block
    )
      no_arg1 = Matcher.undefined?(expression_or_matcher)
      no_arg2 = Matcher.undefined?(matcher)

      if no_arg1 == no_arg2 && no_arg1 ^ block_given?
        raise ArgumentError, "both expression and block given" unless no_arg1

        raise ArgumentError, "neither expression nor block given"
      end

      if block_given?
        expression = ProcExpression.new(block)
        matcher = expression_or_matcher
      else
        expression = expression_of(expression_or_matcher)
      end

      return Chain.new { raises(expression, _1, message:, rescue:) }.optional if
        Matcher.undefined?(matcher)

      matcher = matcher_of(matcher)

      unless Matcher.undefined?(message)
        @raises_message_call ||=
          expression_of(Call.new(Variable.actual, :message))

        message_matcher = matcher_of(message)

        matcher &= ProjectMatcher.new(@raises_message_call, message_matcher)
      end

      RaisesMatcher.new(
        expression, matcher, rescue_exception: { rescue: }[:rescue]
      )
    end
  end
end
