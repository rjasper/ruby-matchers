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

    def ~
      ParseJsonMatcher.new(@original_matcher, json_options: @json_options, negated: !@negated)
    end

    def check(state)
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
    def parse_json(matcher = UNDEFINED, **)
      return Pipe.new { parse_json(_1, **) }.optional if
        Matcher.undefined?(matcher)

      matcher = Matcher.of(matcher)
      json_options = {}.merge(**)
      json_options = nil if json_options.empty?

      ParseJsonMatcher.new(matcher, json_options:)
    end

    def json_format
      @json_format ||= ParseJsonMatcher.new(AlwaysMatcher.instance)
    end
  end
end
