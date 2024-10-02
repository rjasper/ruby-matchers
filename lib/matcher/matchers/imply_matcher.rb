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

    def check(**)
      begin
        condition_errors = @condition.match(**)
      rescue Call::Error => e
        errors << e.message_for_errors
        return
      end

      return unless condition_errors.valid?

      errors << @matcher.match(**)
    end
    protected :check

    def to_s
      "imply(#{@condition}, #{@matcher})"
    end
  end
end
