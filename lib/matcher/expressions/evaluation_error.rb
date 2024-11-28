# frozen_string_literal: true

module Matcher
  class EvaluationError < CallError
    attr_reader :error, :call, :given

    def initialize(error, call, values)
      @error = error
      @call = call
      @given = values.slice(*call.variables)

      super("#{call} raised #{error.class}: #{error.message}")
    end

    def message_for_errors
      Message.new(%i[expression raising], false, nil, @call, @error, @given)
    end
  end
end
