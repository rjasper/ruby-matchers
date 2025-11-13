# frozen_string_literal: true

module Matcher
  class AllMatcher < Base
    def initialize(matchers)
      super()

      @matchers = matchers
    end

    attr_reader :matchers

    def *(matcher)
      matcher = Matcher.cache(matcher)

      if matcher.is_a?(AllMatcher)
        AllMatcher.new(@matchers + matcher.matchers)
      else
        AllMatcher.new(@matchers + [matcher])
      end
    end

    def negate
      AnyMatcher.new(@matchers.map(&:~))
    end

    def validate(state)
      @matchers.each do |matcher|
        state.errors << yield(matcher)
      end
    end

    def to_s
      "all(#{@matchers.map(&:to_s).join(', ')})"
    end
  end

  module MatcherBuilding
    ##
    # Matches all matchers
    # @example
    #   # matches 12 but not 9 or 13
    #   all(_ > 10, _.even?)
    #   # alternatively:
    #   of(_ > 10) * of(_.even?)
    # @param matchers [Array<Base>]
    # @return [AllMatcher]
    # @see Base#*
    def all(*matchers)
      case matchers.length
      when 0
        AlwaysMatcher.instance
      when 1
        matcher_of(matchers[0])
      else
        AllMatcher.new(matchers.map { matcher_of(_1) })
      end
    end
  end
end
