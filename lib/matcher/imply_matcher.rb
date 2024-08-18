# frozen_string_literal: true

module Matcher
  class ImplyMatcher < Base
    attr_reader :condition, :matcher

    def initialize(condition, matcher)
      super()

      @condition = condition
      @matcher = matcher
    end

    def check(actual, **)
      return unless @condition.match(actual, **).valid?

      errors << @matcher.match(actual, **)
    rescue NotRespondingError => e
      errors << e.message_for_errors
    end
    protected :check

    def inspect
      "imply(#{@condition.inspect}, #{@matcher.inspect})"
    end
  end
end
