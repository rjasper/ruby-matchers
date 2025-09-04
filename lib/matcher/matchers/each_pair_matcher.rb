# frozen_string_literal: true

module Matcher
  class EachPairMatcher < Base
    def initialize(matcher)
      super()

      @matcher = matcher
    end

    def negate
      NegatedEachPairMatcher.new(@matcher)
    end

    def validate(state)
      actual = state.actual

      unless actual.respond_to?(:each_pair)
        state.errors << state.expected.responding_to(:each_pair)
        return
      end

      actual.each_pair do |key, value|
        state.errors[key] << yield(
          @matcher,
          [key, value],
          key: key,
          value: value,
          @parent => actual
        )
      end
    end

    def to_s
      "each_pair(#{@matcher})"
    end
  end

  module MatcherBuilding
    def each_pair(matcher = UNDEFINED)
      return Pipe.new { each_pair(_1) } if Matcher.undefined?(matcher)

      EachPairMatcher.new(matcher_of(matcher))
    end

    def each_key(matcher = UNDEFINED)
      return Pipe.new { each_key(_1) } if Matcher.undefined?(matcher)

      matcher = matcher_of(matcher)

      EachPairMatcher.new(
        ProjectMatcher.new(Variable.key, matcher),
      )
    end

    def each_value(matcher = UNDEFINED)
      return Pipe.new { each_value(_1) } if Matcher.undefined?(matcher)

      assigns = { actual: ->(value:) { value } }
      matcher = matcher_of(matcher)

      EachPairMatcher.new(
        LetMatcher.new(assigns, matcher),
      )
    end
  end
end
