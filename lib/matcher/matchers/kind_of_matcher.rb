# frozen_string_literal: true

module Matcher
  class KindOfMatcher < Base
    def initialize(kind, negated: false)
      super()

      @kind = kind
      @negated = negated
    end

    def ~
      KindOfMatcher.new(@kind, negated: !@negated)
    end

    def check(state)
      state.errors << state.expected.not_if(@negated).kind_of(@kind) if
        state.actual.is_a?(@kind) == @negated
    end

    def to_s
      if @negated
        "neg(#{@kind})"
      else
        @kind.to_s
      end
    end
  end
end
