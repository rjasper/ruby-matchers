# frozen_string_literal: true

module Matcher
  class AnyMatcher < Base
    def initialize(matchers)
      super()

      @matchers = matchers
    end

    attr_reader :matchers

    def +(other)
      other = Matcher.cache(other)

      if other.is_a?(AnyMatcher)
        AnyMatcher.new(@matchers + other.matchers)
      else
        AnyMatcher.new(@matchers + [other])
      end
    end

    def negate
      AllMatcher.new(@matchers.map(&:~))
    end

    def validate(state)
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
      "any(#{@matchers.join(', ')})"
    end
  end

  module MatcherBuilding
    ##
    # Matches any matcher
    # @example
    #   # matches "foo" and 1 but not 1.5
    #   any(String, Integer)
    #   # alternatively:
    #   of(String) + of(Integer)
    # @param matchers [Array<Base>]
    # @return [AnyMatcher]
    def any(*matchers)
      case matchers.length
      when 0
        NeverMatcher.instance
      when 1
        matcher_of(matchers[0])
      else
        AnyMatcher.new(matchers.map { matcher_of(_1) })
      end
    end
  end
end
