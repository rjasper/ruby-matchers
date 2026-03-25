# frozen_string_literal: true

require 'time'

module Matcher
  class ParseIso8601Matcher < Base
    def initialize(matcher, negated: false)
      super()

      @matcher = negated ? ~matcher : matcher
      @original_matcher = matcher
      @negated = negated
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
end
