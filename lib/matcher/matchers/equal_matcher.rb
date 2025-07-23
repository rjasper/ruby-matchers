# frozen_string_literal: true

module Matcher
  class EqualMatcher < Base
    def initialize(value, negated: false)
      super()

      @value = value
      @negated = negated
    end

    def ~
      EqualMatcher.new(@value, negated: !@negated)
    end

    def check(state)
      state.errors << expected.not_if(@negated).equal(@value) if
        @negated ^ (state.actual != @value)
    end

    def to_s
      case @value
      when *CASE_EQUALITY_CLASSES
        "#{'~' if @negated}equal(#{@value.inspect})"
      else
        @negated ? "neg(#{@value.inspect})" : @value.inspect
      end
    end
  end

  module MatcherBuilding
    def equal(value)
      EqualMatcher.new(value)
    end
  end
end
