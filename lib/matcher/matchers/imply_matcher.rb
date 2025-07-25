# frozen_string_literal: true

module Matcher
  class ImplyMatcher < Base
    attr_reader :condition, :matcher

    def initialize(condition, matcher)
      super()

      @condition = condition
      @matcher = matcher
    end

    def ~
      NegatedImplyMatcher.new(@condition, @matcher)
    end

    def check(state)
      return unless yield(@condition).valid?

      state.errors << yield(@matcher)
    end

    def to_s
      "imply(#{@condition}, #{@matcher})"
    end
  end

  module MatcherBuilding
    def imply(condition, matcher = UNDEFINED)
      return Pipe.new { imply(condition, _1) } if Matcher.undefined?(matcher)

      condition = Matcher.of(condition)
      matcher = Matcher.of(matcher)

      ImplyMatcher.new(condition, matcher)
    end
  end
end
