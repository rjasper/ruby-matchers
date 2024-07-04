# frozen_string_literal: true

module Matcher
  class AnyMatcher < Base
    def initialize(matchers)
      super()

      @matchers = matchers
    end

    def check(actual)
      found = @matchers.any? do |matcher|
        sub_errors = matcher.match(actual)
        errors << sub_errors

        sub_errors.empty?
      end

      errors.clear if found
    end

    def inspect
      "any(#{@matchers.map(&:inspect).join(', ')})"
    end
  end
end
