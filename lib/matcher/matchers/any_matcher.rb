# frozen_string_literal: true

module Matcher
  class AnyMatcher < Base
    def initialize(matchers)
      super()

      @matchers = matchers
    end

    def |(matcher)
      matcher = Matcher.of(matcher)

      AnyMatcher.new(@matchers + [matcher])
    end

    def ~
      AllMatcher.new(@matchers.map(&:~))
    end

    def check(actual)
      sub_errors = @matchers.map do |matcher|
        sub_error = yield matcher

        return if sub_error.valid?

        sub_error
      end

      errors << Errors::Or.from(sub_errors)
    end
    protected :check

    def to_s
      "any(#{@matchers.map(&:to_s).join(', ')})"
    end
  end

  module MatcherBuilding
    def any(*matchers)
      AnyMatcher.new(matchers.map { Matcher.of(_1) })
    end
  end
end
