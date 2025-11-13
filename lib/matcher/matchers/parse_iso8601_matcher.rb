# frozen_string_literal: true

module Matcher
  class ParseIso8601Matcher < Base
    extend OnceBefore

    def initialize(matcher, negated: false)
      super()

      @matcher = negated ? ~matcher : matcher
      @original_matcher = matcher
      @negated = negated
    end

    once_before :initialize do
      require 'time'
    end

    def negate
      ParseIso8601Matcher.new(@original_matcher, negated: !@negated)
    end

    def validate(state, &)
      actual = state.actual

      unless actual.is_a?(String)
        state.errors << state.expected.kind_of(String) unless @negated
        return
      end

      value = Time.iso8601(actual)

      if @matcher.is_a?(NeverMatcher)
        state.errors << state.expected.not.valid_format(:iso8601)
        return
      end

      result = yield(@matcher, value)

      return if result.valid?

      time_of = Call.new(Constant.new(Time), :iso8601, [Variable.actual])
      state.errors[time_of] << result
    rescue ArgumentError
      state.errors << state.expected.valid_format(:iso8601) unless @negated
    end

    def to_s
      prefix = @negated ? '~' : ''

      return "#{prefix}iso8601_format" if @original_matcher.is_a?(AlwaysMatcher)

      "#{prefix}parse_iso8601(#{@original_matcher})"
    end
  end

  module MatcherBuilding
    ##
    # Parses ISO 8601 time and matches with given matcher
    # @example
    #   # matches "1999-12-31T23:59:00+01:00"
    #   parse_iso8601(_ < expr { Time.now })
    #   # alternatively:
    #   parse_iso8601 ^ (_ < expr { Time.now })
    #   # without matcher matches any valid ISO 8601 string
    #   parse_iso8601
    # @overload parse_iso8601(matcher)
    #   @param matcher [Base]
    #   @return [ParseIso8601Matcher]
    # @overload parse_iso8601
    #   @return [OptionalChain<ParseIso8601Matcher>]
    # @see #iso8601_format
    def parse_iso8601(matcher = UNDEFINED)
      return Chain.new { parse_iso8601(_1) }.optional if
        Matcher.undefined?(matcher)

      matcher = matcher_of(matcher)

      ParseIso8601Matcher.new(matcher)
    end

    ##
    # Matches valid ISO 8601 strings
    # @example
    #   # matches { timestamp: "2025-11-16T21:13:33+01:00" }
    #   { timestamp: iso8601_format }
    # @return [ParseIso8601Matcher]
    def iso8601_format
      @iso8601_format ||= ParseIso8601Matcher.new(AlwaysMatcher.instance)
    end
  end
end
