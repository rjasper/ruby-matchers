# frozen_string_literal: true

module Matcher
  class ParseFloatMatcher < Base
    def initialize(matcher, negated: false)
      super()

      @matcher = negated ? ~matcher : matcher
      @original_matcher = matcher
      @negated = negated
    end

    def ~
      ParseFloatMatcher.new(@original_matcher, negated: !@negated)
    end

    def check(state, &)
      actual = state.actual

      unless actual.is_a?(String)
        state.errors << expected.kind_of(String) unless @negated
        return
      end

      value = Float(actual)
      result = yield(@matcher, value)

      return if result.valid?

      float_of = Call.new(Constant.new(Kernel), :Float, [Variable.actual])
      state.errors[float_of] << result
    rescue ArgumentError
      state.errors << expected.valid_format(:float) unless @negated
    end

    def to_s
      "#{'~' if @negated}parse_float(#{@original_matcher})"
    end
  end

  module MatcherBuilding
    def parse_float(matcher = UNDEFINED)
      return Pipe.new { parse_float(_1) } if Matcher.undefined?(matcher)

      matcher = Matcher.of(matcher)

      ParseFloatMatcher.new(matcher)
    end
  end
end
