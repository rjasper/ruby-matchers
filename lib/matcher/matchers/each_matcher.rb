# frozen_string_literal: true

module Matcher
  ##
  # Match each item.
  # @example
  #   m = Matcher.build { each(Integer) }
  #
  #   m.match?([1, 2, 3])
  #   # => true
  #   m.match([1, "foo"])
  #   # > root[1]: expected a kind of Integer but got "foo"
  #
  #   # "each" passes index and parent to its item matcher:
  #   m = Matcher.build { each(_ == i) }
  #   m.match?([0, 1]) # => true
  #   m.match?([0, 2]) # => false
  #
  #   m = Matcher.build { each(_ < parent.length) }
  #   m.match?([1, 0, 2]) # => true
  #   m.match?([1, 2, 3]) # => false
  class EachMatcher < Base
    def initialize(matcher)
      super()

      @matcher = matcher
    end

    def negate
      NegatedEachMatcher.new(@matcher)
    end

    def validate(state)
      unless state.actual.respond_to?(:each)
        state.errors << state.expected.responding_to(:each)
        return
      end

      i = 0
      state.actual.each do |item|
        state.errors[i] << yield(@matcher, item, index: i, parent: state.actual)
        i += 1
      end
    end

    def to_s
      "each(#{@matcher})"
    end
  end

  module MatcherDsl
    ##
    # Matches each item with matcher
    #
    # == +matcher+ values
    #
    # Passes +index+
    #
    #   m = Matcher.build { each(_ == i) }
    #   m.match?([0, 1]) # => true
    #   m.match?([0, 2]) # => false
    #
    # Passes +parent+
    #
    #   m = Matcher.build { each(_ < parent.length) }
    #   m.match?([1, 0, 2]) # => true
    #   m.match?([1, 2, 3]) # => false
    #
    # @example
    #   # matches [1, 2] but not [1, "foo"]
    #   each(Integer)
    #   # alternatively:
    #   each ^ Integer
    # @overload each(matcher)
    #   @param matcher [Base]
    #   @return [EachMatcher]
    # @overload each
    #   @return [Chain<EachMatcher>]
    def each(matcher = UNDEFINED)
      return Chain.new { each(_1) } if Matcher.undefined?(matcher)

      EachMatcher.new(matcher_of(matcher))
    end
  end
end
