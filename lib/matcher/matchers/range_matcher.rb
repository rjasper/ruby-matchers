# frozen_string_literal: true

module Matcher
  class RangeMatcher < Base
    def self.cache(range, matcher_cache = MatcherCache.current)
      return new(range) unless matcher_cache

      (matcher_cache.range_matchers ||= {})[range] ||= new(range)
    end

    def initialize(range, negated: false)
      super()

      @range = range
      @negated = negated
    end

    def negate
      RangeMatcher.new(@range, negated: !@negated)
    end

    def validate(state)
      limit = @range.begin || @range.end

      if (limit <=> state.actual).nil?
        state.errors << state.expected.comparable_to(@range.begin) unless @negated
        return
      end

      return if @range.include?(state.actual) ^ @negated

      state.errors << state.expected.not_if(@negated).between(
        @range.begin,
        @range.end,
        exclude_end: @range.exclude_end?,
      )
    end

    def to_s
      if @negated
        "neg(#{@range})"
      else
        @range.to_s
      end
    end
  end
end
