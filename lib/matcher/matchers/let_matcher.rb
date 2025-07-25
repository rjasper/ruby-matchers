# frozen_string_literal: true

module Matcher
  class LetMatcher < Base
    def initialize(assigns, matcher)
      super()

      @assigns = assigns
      @matcher = matcher
    end

    def ~
      LetMatcher.new(@assigns, ~@matcher)
    end

    def check(state)
      assigns = @assigns.transform_values do |v|
        v.is_a?(Proc) ? Utils.call_block(v, state.values) : v
      end

      state.errors << yield(@matcher, assigns[:actual] || state.actual, **assigns)
    end

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

      "let(#{assign_parts.join(', ')}) ^ #{matcher}"
    end
  end

  module MatcherBuilding
    def let(assigns = nil, matcher = UNDEFINED, **kwargs)
      raise "Cannot set both assigns and kwargs" if assigns && !kwargs.empty?

      assigns = kwargs unless assigns

      return Pipe.new { let(assigns, _1) } if Matcher.undefined?(matcher)

      matcher = Matcher.of(matcher)

      LetMatcher.new(assigns, matcher)
    end
  end
end
