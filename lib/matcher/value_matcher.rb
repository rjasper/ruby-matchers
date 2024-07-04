# frozen_string_literal: true

module Matcher
  class ValueMatcher < Base
    def initialize(value)
      super()

      @value = value
    end

    def check(actual)
      errors << not_equal_message(actual) if actual != @value
    end

    def inspect
      @value.inspect
    end

    private

    def not_equal_message(actual)
      "expected #{@value.inspect} but got #{actual.inspect}"
    end
  end
end
