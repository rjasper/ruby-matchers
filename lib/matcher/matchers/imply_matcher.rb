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
      begin
        return unless yield(@condition).valid?
      rescue Call::Error => e
        errors << e.message_for_errors
        return
      end

      errors << yield(@matcher)
    end
    protected :check

    def to_s
      "imply(#{@condition}, #{@matcher})"
    end
  end
end
