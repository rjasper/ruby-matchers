# frozen_string_literal: true

module Matcher
  class EachPairMatcher < Base
    def initialize(matcher, negated: false)
      super()

      @matcher = negated ? ~matcher : matcher
      @original_matcher = matcher
      @negated = negated
    end

    def negate
      EachPairMatcher.new(@original_matcher, negated: !@negated)
    end

    def validate(state, &)
      return validate_negated(state, &) if @negated

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
      "#{"~" if @negated}each_pair(#{@original_matcher})"
    end

    private

    def validate_negated(state)
      actual = state.actual

      return unless actual.respond_to?(:each_pair)

      collector = state.new_collector.or!

      actual.each do |key, value|
        result = yield(@matcher, [key, value], key:, value:, parent: actual)

        return nil if result.valid?

        collector[key] << result
      end

      state.errors << collector.error
    end
  end

  module MatcherDsl
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
