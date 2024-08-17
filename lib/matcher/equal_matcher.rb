# frozen_string_literal: true

module Matcher
  class EqualMatcher < Base
    def initialize(value)
      super()

      @value = value
    end

    def check(actual, **)
      errors << not_equal_message(actual) unless actual == @value
    end

    def inspect
      case @value
      when *CASE_EQUALITY_CLASSES
        "equal(#{@value.inspect})"
      else
        @value.inspect
      end
    end

    private

    def not_equal_message(actual)
      "expected #{@value.inspect} but got #{actual.inspect}"
    end
  end
end
