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

    def negated
      ImplyMatcher.new(@condition, @matcher)
    end

    def check(**)
      begin
        condition_errors = @condition.match(**)
      rescue NotRespondingError => e
        return
      end

      unless condition_errors.valid?
        errors << condition_errors
        return
      end

      errors << @neg_matcher.match(**)
    end
    protected :check

    def to_s
      "~imply(#{@condition}, #{@matcher})"
    end
  end
end
