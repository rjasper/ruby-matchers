# frozen_string_literal: true

module Matcher
  class LetMatcher < Base
    def initialize(assigns, matcher)
      super()

      @assigns = assigns
      @matcher = matcher
    end

    def negate
      LetMatcher.new(@assigns, ~@matcher)
    end

    def validate(state)
      assigns = @assigns.transform_values do |v|
        v = Expression.try_recorder(v)

        case v
        when Proc
          Utils.call_block(v, state.values)
        when Expression
          v.evaluate(state.values)
        else
          v
        end
      end

      state.errors << yield(@matcher, **assigns)
    end

    def to_s
      assign_parts = @assigns.map do |key, value|
        if value.is_a?(Proc)
          "#{key}: ->(#{Utils.inspect_block_params(value)}) { ... }"
        else
          "#{key}: #{value.inspect}"
        end
      end

      "let(#{assign_parts.join(', ')}) ^ #{Matcher.parenthesize(@matcher)}"
    end
  end

  module MatcherBuilding
    def let(assigns = nil, matcher = UNDEFINED, **kwargs)
      raise "Cannot set both assigns and kwargs" if assigns && !kwargs.empty?

      assigns ||= kwargs

      return Pipe.new { let(assigns, _1) } if Matcher.undefined?(matcher)

      matcher = matcher_of(matcher)

      LetMatcher.new(assigns, matcher)
    end
  end
end
