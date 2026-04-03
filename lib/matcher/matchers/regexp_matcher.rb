# frozen_string_literal: true

module Matcher
  class RegexpMatcher < Base
    def self.cache(pattern, matcher_cache = MatcherCache.current)
      return new(pattern) unless matcher_cache

      (matcher_cache.regexp_matchers ||= {})[pattern] ||= new(pattern)
    end

    def initialize(pattern, matcher = AlwaysMatcher.instance, negated: false)
      super()

      @pattern = pattern
      @matcher = negated ? ~matcher : matcher
      @original_matcher = matcher
      @negated = negated
    end

    def negate
      RegexpMatcher.new(@pattern, @original_matcher, negated: !@negated)
    end

    def validate(state)
      unless state.actual.is_a?(String)
        state.errors << state.expected.kind_of(String) unless @negated
        return
      end

      if @original_matcher == AlwaysMatcher.instance
        state.errors << state.expected.not_if(@negated).matching(@pattern) if
          @pattern.match?(state.actual) == @negated
      else
        match = @pattern.match(state.actual)

        if match
          state.errors[match_pattern_call] << yield(@matcher, match)
        else
          state.errors << state.expected.matching(@pattern) unless @negated
        end
      end
    end

    def match_pattern_call
      @match_pattern_call ||=
        Call.new(Variable.actual, :match, [Constant.new(@pattern)])
    end

    def to_s
      if @original_matcher == AlwaysMatcher.instance
        if @negated
          "neg(#{@pattern.inspect})"
        else
          @pattern.inspect
        end
      else
        "#{'~' if @negated}regexp(#{@pattern.inspect}, #{@original_matcher})"
      end
    end
  end

  module MatcherDsl
    ##
    # Matches regular expression and passes MatchData to matcher
    # @example
    #   # matches "x=5" but not "y=5" or "x=20"
    #   regexp(/x=(\d+)/, project(_[1].to_i => 0..10))
    #   # alternatively:
    #   regexp(/x=(\d+)/) ^ project(_[1].to_i => 0..10)
    #   # without matcher passes if regular expression matches
    #   regexp(/x=\d+/)
    # @overload regexp(pattern, matcher)
    #   @param pattern [Regexp]
    #   @param matcher [Base]
    #   @return [RegexpMatcher]
    # @overload regexp(pattern)
    #   @param pattern [Regexp]
    #   @return [OptionalChain<RegexpMatcher>]
    def regexp(pattern, matcher = UNDEFINED)
      return Chain.new { regexp(pattern, _1) }.optional if
        Matcher.undefined?(matcher)

      RegexpMatcher.new(pattern, matcher_of(matcher))
    end
  end
end
