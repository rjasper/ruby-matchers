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
      NamespacedMessageBuilder.new(
        !@matcher.negated, @state.actual, :expression
      )
    end

    def given
      @matcher.expression.given_for(@state.values)
    end
  end
end
