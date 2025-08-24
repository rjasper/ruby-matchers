# frozen_string_literal: true

module Matcher
  class RegexpMatcher < Base
    def initialize(pattern, negated: false)
      super()

      @pattern = pattern
      @negated = negated
    end

    def ~
      RegexpMatcher.new(@pattern, negated: !@negated)
    end

    def check(state)
      unless state.actual.is_a?(String)
        state.errors << state.expected.kind_of(String) unless @negated
        return
      end

      state.errors << state.expected.not_if(@negated).matching(@pattern) if
        @pattern.match?(state.actual) == @negated
    end

    def to_s
      if @negated
        "neg(#{@pattern.inspect})"
      else
        @pattern.inspect
      end
    end
  end
end
