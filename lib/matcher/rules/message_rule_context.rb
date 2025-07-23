# frozen_string_literal: true

module Matcher
  class MessageRuleContext
    extend Forwardable

    def initialize(matcher, state)
      @matcher = matcher
      @state = state
    end

    def standard_message
      StandardMessageBuilder.new(!@matcher.negated, @state.actual)
    end

    def expression_message
      NamespacedMessageBuilder.new(!@matcher.negated, @state.actual, :expression)
    end

    def given
      state_values = @state.values

      @matcher.expression.variables.each_with_object({}) do |symbol, given|
        given[symbol] = state_values[symbol]
      end
    end
  end
end
