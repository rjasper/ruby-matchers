# frozen_string_literal: true

module Matcher
  class ParseTimeMatcher < Base
    def initialize(matcher, negated: false)
      super()

      @matcher = negated ? ~matcher : matcher
      @original_matcher = matcher
      @negated = negated
    end

    def ~
      ParseTimeMatcher.new(@original_matcher, negated: !@negated)
    end

    def check(state, &)
      actual = state.actual

      unless actual.is_a?(String)
        state.errors << expected.kind_of(String) unless @negated
        return
      end

      value = Time.parse(actual)
      result = yield(@matcher, value)

      return if result.valid?

      time_of = Call.new(Constant.new(Time), :parse, [Variable.actual])
      state.errors[time_of] << result
    rescue ArgumentError
      state.errors << expected.valid_format(:time) unless @negated
    end

    def to_s
      "#{'~' if @negated}parse_time(#{@original_matcher})"
    end
  end

  module MatcherBuilding
    def parse_time(matcher = UNDEFINED)
      return Pipe.new { parse_time(_1) } if Matcher.undefined?(matcher)

      matcher = Matcher.of(matcher)

      ParseTimeMatcher.new(matcher)
    end
  end
end
