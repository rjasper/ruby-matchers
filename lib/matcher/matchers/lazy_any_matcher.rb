# frozen_string_literal: true

module Matcher
  class LazyAnyMatcher < Base
    def initialize(matchers)
      super()

      @matchers = matchers
    end

    attr_reader :matchers

    def negate
      LazyAllMatcher.new(@matchers.map(&:~))
    end

    def |(matcher)
      matcher = Matcher.cache(matcher)

      if matcher.is_a?(LazyAnyMatcher)
        LazyAnyMatcher.new(@matchers + matcher.matchers)
      else
        LazyAnyMatcher.new(@matchers + [matcher])
      end
    end

    def validate(state)
      last_error = EmptyError.instance

      @matchers.each do |matcher|
        last_error = yield matcher

        break if last_error.valid?
      end

      state.errors << last_error
    end

    def to_s
      "lazy_any(#{@matchers.map(&:to_s).join(', ')})"
    end
  end

  module MatcherBuilding
    ##
    # Matches any matcher lazily. Returns only the last match result (similar to ||)
    # @example
    #   # matches "foo" and 42 but not +nil+ or +true+
    #   lazy_any(String, Integer)
    #   # alternatively:
    #   of(String) | of(Integer)
    # @param matchers [Array<Base>]
    # @return [LazyAnyMatcher]
    # @see Base#|
    # @see #lazy_all
    # @see #any
    def lazy_any(*matchers)
      case matchers.length
      when 0
        AlwaysMatcher.instance
      when 1
        matcher_of(matchers[0])
      else
        LazyAnyMatcher.new(matchers.map { matcher_of(_1) })
      end
    end
  end
end
