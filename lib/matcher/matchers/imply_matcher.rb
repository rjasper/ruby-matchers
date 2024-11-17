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

    def check(_actual)
      return unless yield(@condition).valid?

      errors << yield(@matcher)
    end
    protected :check

    def to_s
      "imply(#{@condition}, #{@matcher})"
    end
  end

  module MatcherBuilding
    def imply(condition, matcher = NULL)
      return Pipe.new { imply(condition, _1) } if Matcher.null?(matcher)

      condition = Matcher.of(condition)
      matcher = Matcher.of(matcher)

      ImplyMatcher.new(condition, matcher)
    end
  end
end
