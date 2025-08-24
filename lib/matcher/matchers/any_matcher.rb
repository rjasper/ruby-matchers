# frozen_string_literal: true

module Matcher
  class AnyMatcher < Base
    def initialize(matchers)
      super()

      @matchers = matchers
    end

    attr_reader :matchers

    def +(matcher)
      matcher = Matcher.of(matcher)

      if matcher.is_a?(AnyMatcher)
        AnyMatcher.new(@matchers + matcher.matchers)
      else
        AnyMatcher.new(@matchers + [matcher])
      end
    end

    def ~
      AllMatcher.new(@matchers.map(&:~))
    end

    def check(state)
      if @matchers.empty?
        state.errors << state.report.exist
        return
      end

      sub_errors = @matchers.map do |matcher|
        sub_error = yield matcher

        return if sub_error.valid?

        sub_error
      end

      state.errors << OrError.from(sub_errors)
    end

    def to_s
      "any(#{@matchers.map(&:to_s).join(', ')})"
    end
  end

  module MatcherBuilding
    def any(*matchers)
      case matchers.length
      when 0
        NeverMatcher.instance
      when 1
        Matcher.of(matchers[0])
      else
        AnyMatcher.new(matchers.map { Matcher.of(_1) })
      end
    end
  end
end
