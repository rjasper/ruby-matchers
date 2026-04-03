# frozen_string_literal: true

module Matcher
  class LazyAllMatcher < Base
    def initialize(matchers)
      super()

      @matchers = matchers
    end

    attr_reader :matchers

    def negate
      LazyAnyMatcher.new(@matchers.map(&:~))
    end

    def &(other)
      other = Matcher.cache(other)

      if other.is_a?(LazyAllMatcher)
        LazyAllMatcher.new(@matchers + other.matchers)
      else
        LazyAllMatcher.new(@matchers + [other])
      end
    end

    def validate(state)
      last_error = EmptyError.instance

      @matchers.each do |matcher|
        last_error = yield matcher

        break unless last_error.valid?
      end

      state.errors << last_error
    end

    def to_s
      "lazy_all(#{@matchers.join(', ')})"
    end
  end

  module MatcherBuilding
    ##
    # Matches all matchers lazily. Returns only the last match result
    # (similar to &&).
    # @example
    #   # matches 3 but not "foo"
    #   lazy_all(Integer, _ % 3 == 0)
    #   # alternatively:
    #   of(Integer) & _.positive?
    # @param matchers [Array<Base>]
    # @return [LazyAllMatcher]
    # @see Base#&
    # @see #lazy_any
    # @see #all
    def lazy_all(*matchers)
      case matchers.length
      when 0
        AlwaysMatcher.instance
      when 1
        matcher_of(matchers[0])
      else
        LazyAllMatcher.new(matchers.map { matcher_of(_1) })
      end
    end
  end
end
