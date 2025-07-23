# frozen_string_literal: true

module Matcher
  class NegatedImplyMatcher < Base
    attr_reader :condition, :matcher

    def initialize(condition, matcher)
      super()

      @condition = condition
      @matcher = matcher
      @neg_matcher = ~matcher
    end

    def ~
      ImplyMatcher.new(@condition, @matcher)
    end

    def check(state)
      condition_errors = yield @condition

      state.errors << if condition_errors.valid?
        yield(@neg_matcher)
      else
        condition_errors
      end
    end

    def to_s
      "~imply(#{@condition}, #{@matcher})"
    end
  end
end
