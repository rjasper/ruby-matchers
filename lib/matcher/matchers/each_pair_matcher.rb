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
          parent: actual
        )
      end
    end

    def to_s
      "each_pair(#{@matcher})"
    end
  end

  module MatcherBuilding
    ##
    # Matches each hash entry
    # == +matcher+ values
    # - key
    # - value
    # - parent
    # @example
    #   # matches { foo: "foo" } but not { foo: "bar" }
    #   each_pair(k.to_s == v)
    #   # alternatively:
    #   each_pair ^ (k.to_s == v)
    # @overload each_pair(matcher)
    #   @param matcher [Base]
    #   @return [EachPairMatcher]
    # @overload each_pair
    #   @return [Chain<EachPairMatcher>]
    # @see #each_key
    # @see #each_value
    def each_pair(matcher = UNDEFINED)
      return Chain.new { each_pair(_1) } if Matcher.undefined?(matcher)

      EachPairMatcher.new(matcher_of(matcher))
    end

    ##
    # Matches each hash key
    # == +matcher+ values
    # - key
    # - value
    # - parent
    # @example
    #   # matches { foo: 1, bar: 2 } but not { "foo" => 1, "bar" => 2 }
    #   each_key(Symbol)
    #   # alternatively:
    #   each_key ^ Symbol
    # @overload each_key(matcher)
    #   @param matcher [Base]
    #   @return [EachPairMatcher]
    # @overload each_key
    #   @return [Chain<EachPairMatcher>]
    # @see #each_pair
    def each_key(matcher = UNDEFINED)
      return Chain.new { each_key(_1) } if Matcher.undefined?(matcher)

      matcher = matcher_of(matcher)

      EachPairMatcher.new(
        ProjectMatcher.new(Variable.key, matcher),
      )
    end

    ##
    # Matches each hash value
    # == +matcher+ values
    # - key
    # - value
    # - parent
    # @example
    #   # matches { a: "foo", b: "bar" } but not { a: 1, b: 2 }
    #   each_value(String)
    #   # alternatively:
    #   each_value ^ String
    # @overload each_value(matcher)
    #   @param matcher [Base]
    #   @return [EachPairMatcher]
    # @overload each_value
    #   @return [Chain<EachPairMatcher>]
    # @see #each_pair
    def each_value(matcher = UNDEFINED)
      return Chain.new { each_value(_1) } if Matcher.undefined?(matcher)

      assigns = { actual: Variable.value }
      matcher = matcher_of(matcher)

      EachPairMatcher.new(
        LetMatcher.new(assigns, matcher),
      )
    end
  end
end
