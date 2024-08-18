# frozen_string_literal: true

module Matcher
  class CaseEqualityMatcher < Base
    def initialize(object)
      super()

      @object = object
    end

    def check(actual, **)
      errors << not_equal_message(actual) unless @object === actual # rubocop:disable Style/CaseEquality
    end
    protected :check

    def inspect
      @object.inspect
    end

    private

    def not_equal_message(actual)
      case @object
      when Class
        "expected #{actual.inspect} to be kind of #{@object}"
      when Range
        "expected #{actual.inspect} to be within #{@object}"
      when Regexp
        "expected #{actual.inspect} to match #{@object.inspect}"
      when Set
        "expected #{actual.inspect} to be member of {#{@object.join(', ')}}"
      else
        "expected #{@object.inspect} but got #{actual.inspect}"
      end
    end
  end
end
