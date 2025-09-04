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
