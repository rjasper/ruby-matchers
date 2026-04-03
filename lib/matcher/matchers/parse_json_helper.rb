# frozen_string_literal: true

module Matcher
  autoload :ParseJsonMatcher, "matcher/matchers/parse_json_matcher"

  module MatcherDsl
    ##
    # Parses JSON and matches with given matcher
    # @example
    #   # matches '{"foo":42}'
    #   parse_json({ "foo" => Integer })
    #   # alternatively:
    #   parse_json ^ { "foo" => Integer }
    #   # without matcher matches any valid JSON string
    #   parse_json
    # @overload parse_json(matcher, **json_options)
    #   @param matcher [Base]
    #   @return [ParseJsonMatcher]
    # @overload parse_json(**json_options)
    #   @return [OptionalChain<ParseJsonMatcher>]
    # @see #json_format
    def parse_json(matcher = UNDEFINED, **)
      return Chain.new { parse_json(_1, **) }.optional if
        Matcher.undefined?(matcher)

      matcher = matcher_of(matcher)
      json_options = {}.merge(**)
      json_options = Compatibility::NULL_KWARGS if json_options.empty?

      ParseJsonMatcher.new(matcher, json_options:)
    end

    ##
    # Matches valid JSON strings
    # @example
    #   # matches { payload: '{"foo":42}' }
    #   { payload: json_format }
    # @return [ParseJsonMatcher]
    def json_format
      @json_format ||= ParseJsonMatcher.new(AlwaysMatcher.instance)
    end
  end
end
