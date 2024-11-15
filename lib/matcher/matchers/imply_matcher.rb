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
end
