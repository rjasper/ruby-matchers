# frozen_string_literal: true

module Matcher
  class AllMatcher < Base
    def initialize(matchers)
      super()

      @matchers = matchers
    end

    attr_reader :matchers

    def *(other)
      other = Matcher.cache(other)

      if other.is_a?(AllMatcher)
        AllMatcher.new(@matchers + other.matchers)
      else
        AllMatcher.new(@matchers + [other])
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
      "all(#{@matchers.join(', ')})"
    end
  end

  module MatcherDsl
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
