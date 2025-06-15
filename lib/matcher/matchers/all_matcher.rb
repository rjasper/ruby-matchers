# frozen_string_literal: true

module Matcher
  class AllMatcher < Base
    def initialize(matchers)
      super()

      @matchers = matchers
    end

    attr_reader :matchers

    def &(matcher)
      matcher = Matcher.of(matcher)

      AllMatcher.new(@matchers + [matcher])
    end

    def ~
      AnyMatcher.new(@matchers.map(&:~))
    end

    def check(actual)
      @matchers.each do |matcher|
        errors << yield(matcher)
      end
    end
    protected :check

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
        Matcher.of(matchers[0])
      else
        AllMatcher.new(matchers.map { Matcher.of(_1) })
      end
    end
  end
end
