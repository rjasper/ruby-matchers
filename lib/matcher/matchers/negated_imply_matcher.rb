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

    def check(_actual)
      begin
        condition_errors = yield @condition
      rescue Call::Error
        return
      end

      unless condition_errors.valid?
        errors << condition_errors
        return
      end

      errors << yield(@neg_matcher)
    end
    protected :check

    def to_s
      "~imply(#{@condition}, #{@matcher})"
    end
  end
end
