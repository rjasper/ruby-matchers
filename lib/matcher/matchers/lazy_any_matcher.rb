# frozen_string_literal: true

module Matcher
  class LazyAnyMatcher < Base
    def initialize(matchers)
      super()

      @matchers = matchers
    end

    attr_reader :matchers

    def ~
      LazyAllMatcher.new(@matchers.map(&:~))
    end

    def |(matcher)
      matcher = Matcher.of(matcher)

      if matcher.is_a?(LazyAnyMatcher)
        LazyAnyMatcher.new(@matchers + matcher.matchers)
      else
        LazyAnyMatcher.new(@matchers + [matcher])
      end
    end

    def check(state)
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
    def lazy_any(*matchers)
      case matchers.length
      when 0
        AlwaysMatcher.instance
      when 1
        Matcher.of(matchers[0])
      else
        LazyAnyMatcher.new(matchers.map { Matcher.of(_1) })
      end
    end
  end
end
