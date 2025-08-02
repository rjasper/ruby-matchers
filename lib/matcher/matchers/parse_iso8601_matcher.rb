# frozen_string_literal: true

module Matcher
  class ParseIso8601Matcher < Base
    def initialize(matcher, negated: false)
      super()

      @matcher = negated ? ~matcher : matcher
      @original_matcher = matcher
      @negated = negated
    end

    def ~
      ParseIso8601Matcher.new(@original_matcher, negated: !@negated)
    end

    def check(state, &)
      actual = state.actual

      unless actual.is_a?(String)
        state.errors << expected.kind_of(String) unless @negated
        return
      end

      value = Time.iso8601(actual)
      result = yield(@matcher, value)

      return if result.valid?

      time_of = Call.new(Constant.new(Time), :iso8601, [Variable.actual])
      state.errors[time_of] << result
    rescue ArgumentError
      state.errors << expected.valid_format(:iso8601) unless @negated
    end

    def to_s
      "#{'~' if @negated}parse_iso8601(#{@original_matcher})"
    end
  end

  module MatcherBuilding
    def parse_iso8601(matcher = UNDEFINED)
      return Pipe.new { parse_iso8601(_1) } if Matcher.undefined?(matcher)

      matcher = Matcher.of(matcher)

      ParseIso8601Matcher.new(matcher)
    end
  end
end
