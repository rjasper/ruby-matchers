# frozen_string_literal: true

module Matcher
  autoload :ParseIso8601Matcher, "matcher/matchers/parse_iso8601_matcher"

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
