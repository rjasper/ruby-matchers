# frozen_string_literal: true

module Matcher
  class OptionalMatcher < Base
    def initialize(matcher, negated: false)
      super()

      @matcher = negated ? ~matcher : matcher
      @original_matcher = matcher
      @negated = negated
    end

    def ~
      OptionalMatcher.new(@original_matcher, negated: !@negated)
    end

    def check(state)
      if state.actual.nil?
        state.errors << state.expected.not.equal(nil) if @negated
      else
        state.errors << yield(@matcher)
      end
    end

    def to_s
      "#{'~' if @negated}optional(#{@original_matcher})"
    end
  end

  # see Optional for optional helper
end
