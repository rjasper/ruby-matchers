# frozen_string_literal: true

module Matcher
  class ParseJsonMatcher < Base
    extend OnceBefore

    def initialize(matcher, json_options: nil, negated: false)
      super()

      @matcher = negated ? ~matcher : matcher
      @original_matcher = matcher
      @json_options = json_options
      @negated = negated
    end

    once_before :initialize do
      require 'json'
    end

    def negate
      ParseJsonMatcher.new(@original_matcher, json_options: @json_options, negated: !@negated)
    end

    def validate(state)
      actual = state.actual

      unless actual.is_a?(String)
        state.errors << state.expected.kind_of(String) unless @negated
        return
      end

      value = JSON.parse(actual, **@json_options)

      if @matcher.is_a?(NeverMatcher)
        state.errors << state.expected.not.valid_format(:json)
        return
      end

      result = yield(@matcher, value)

      return if result.valid?

      parse_json = Call.new(Constant.new(JSON), :parse, [Variable.actual])
      state.errors[parse_json] << result
    rescue JSON::ParserError
      state.errors << state.expected.valid_format(:json) unless @negated
    end

    def to_s
      prefix = @negated ? '~' : ''

      return "#{prefix}json_format" if @original_matcher.is_a?(AlwaysMatcher)

      "#{prefix}parse_json(#{@original_matcher})"
    end
  end

  module MatcherBuilding
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
      json_options = nil if json_options.empty?

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
