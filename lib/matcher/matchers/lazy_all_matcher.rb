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

    def &(matcher)
      matcher = Matcher.cache(matcher)

      if matcher.is_a?(LazyAllMatcher)
        LazyAllMatcher.new(@matchers + matcher.matchers)
      else
        LazyAllMatcher.new(@matchers + [matcher])
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
      "lazy_all(#{@matchers.map(&:to_s).join(', ')})"
    end
  end

  module MatcherBuilding
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
