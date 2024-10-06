# frozen_string_literal: true

module Matcher
  class SetVariablesMatcher < Base
    def initialize(assigns, matcher)
      super()

      @assigns = assigns
      @matcher = matcher
    end

    def ~
      SetVariablesMatcher.new(@assigns, ~@matcher)
    end

    def check(actual)
      block_values = values.merge(actual:)
      assigns = @assigns.transform_values do |v|
        v.is_a?(Proc) ? Utils.call_block(v, block_values) : v
      end

      errors << yield(@matcher, **assigns)
    end
    protected :check

    def to_s
      assign_parts = @assigns.map do |key, value|
        if value.is_a?(Proc)
          "#{key}: ->(#{Utils.inspect_block_params(value)}) { ... }"
        else
          "#{key}: #{value.inspect}"
        end
      end

      matcher = @matcher.to_s

      matcher = "(#{matcher})" if
        case @matcher
        when ExpressionMatcher
          !@matcher.negated && @matcher.expression.precedence > Call::OPERATOR_PRECEDENCE[:^]
        when EqualMatcher, CaseEqualityMatcher, ArrayMatcher, HashMatcher
          false
        else
          matcher !~ /\A(~?\w+(\(.*\)|\[.*\])?|-> \{.*})\z/
        end

      "setvar(#{assign_parts.join(', ')}) ^ #{matcher}"
    end
  end
end
