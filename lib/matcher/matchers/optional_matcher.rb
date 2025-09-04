# frozen_string_literal: true

module Matcher
  class OptionalMatcher < Base
    def self.cache(matcher, matcher_cache = MatcherCache.current)
      return new(matcher) unless matcher_cache

      cache = (matcher_cache.optional_matchers ||= {}.compare_by_identity)
      cache[matcher] ||= new(matcher)
    end

    def initialize(matcher, negated: false)
      super()

      @matcher = negated ? ~matcher : matcher
      @original_matcher = matcher
      @negated = negated
    end

    def negate
      OptionalMatcher.new(@original_matcher, negated: !@negated)
    end

    def validate(state)
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
