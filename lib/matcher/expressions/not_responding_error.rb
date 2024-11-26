# frozen_string_literal: true

module Matcher
  class NotRespondingError < CallError
    attr_reader :call, :receiver, :given

    def initialize(call, receiver, values)
      @call = call
      @receiver = receiver
      @given = values.slice(*call.receiver.variables)

      super("#{call.receiver} does not respond to `#{call.method}'")
    end

    def message_for_errors
      if @call.receiver == Variable.actual
        ErrorMessage.new(:responding_to, true, @receiver, @call.method)
      else
        ErrorMessage.new(
          %i[expression responding_to],
          true,
          nil,
          @call.receiver,
          @receiver,
          @call.method,
          @given,
        )
      end
    end
  end
end
