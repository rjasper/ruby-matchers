# frozen_string_literal: true

module Matcher
  class CallError < StandardError
    attr_reader :call, :given

    def initialize(message, call, given)
      super(message)

      @call = call
      @given = given
    end

    def message_for_errors(actual)
      case cause
      when NoMethodError
        not_responding_message(actual)
      else
        raising_message(actual)
      end
    end

    private

    def raising_message(actual)
      Message.new(%i[expression raising], false, actual, @call, cause, @given)
    end

    def not_responding_message(actual)
      if @call.receiver == Variable.actual
        Message.new(:responding_to, true, cause.receiver, @call.method)
      else
        Message.new(
          %i[expression responding_to],
          true,
          actual,
          @call.receiver,
          cause.receiver,
          @call.method,
          @given,
        )
      end
    end
  end
end
