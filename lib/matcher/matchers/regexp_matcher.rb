# frozen_string_literal: true

module Matcher
  class RegexpMatcher < Base
    def self.cache(pattern, matcher_cache = MatcherCache.current)
      return new(pattern) unless matcher_cache

      (matcher_cache.regexp_matchers ||= {})[pattern] ||= new(pattern)
    end

    def initialize(pattern, negated: false)
      super()

      @pattern = pattern
      @negated = negated
    end

    def negate
      RegexpMatcher.new(@pattern, negated: !@negated)
    end

    def validate(state)
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
