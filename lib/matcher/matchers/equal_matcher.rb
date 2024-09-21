# frozen_string_literal: true

module Matcher
  class EqualMatcher < Base
    def initialize(value, negated: false)
      super()

      @value = value
      @negated = negated
    end

    def negated
      EqualMatcher.new(@value, negated: !@negated)
    end

    def check(actual:, **)
      errors << message_for(actual) if @negated ^ (actual != @value)
    end
    protected :check

    def inspect
      case @value
      when *CASE_EQUALITY_CLASSES
        "#{'~' if @negated}equal(#{@value.inspect})"
      else
        @negated ? "neg(#{@value.inspect})" : @value.inspect
      end
    end

    private

    def message_for(actual)
      if @negated
        "expected #{actual.inspect} to not be #{@value.inspect}"
      else
        "expected #{@value.inspect} but got #{actual.inspect}"
      end
    end
  end
end
