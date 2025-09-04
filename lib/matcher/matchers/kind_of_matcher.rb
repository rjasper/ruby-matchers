# frozen_string_literal: true

module Matcher
  class KindOfMatcher < Base
    def self.cache(kind, matcher_cache = MatcherCache.current)
      return new(kind) unless matcher_cache

      (matcher_cache.kind_of_matchers ||= {})[kind] ||= new(kind)
    end

    def initialize(kind, negated: false)
      super()

      @kind = kind
      @negated = negated
    end

    def negate
      KindOfMatcher.new(@kind, negated: !@negated)
    end

    def validate(state)
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
