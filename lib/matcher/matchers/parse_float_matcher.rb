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
        state.errors << state.expected.kind_of(String) unless @negated
        return
      end

      value = Float(actual)

      if @matcher.is_a?(NeverMatcher)
        state.errors << state.expected.not.valid_format(:float)
        return
      end

      result = yield(@matcher, value)

      return if result.valid?

      float_of = Call.new(Constant.new(Kernel), :Float, [Variable.actual])
      state.errors[float_of] << result
    rescue ArgumentError
      state.errors << state.expected.valid_format(:float) unless @negated
    end

    def to_s
      prefix = @negated ? '~' : ''

      return "#{prefix}float_format" if @original_matcher.is_a?(AlwaysMatcher)

      "#{prefix}parse_float(#{@original_matcher})"
    end
  end

  module MatcherBuilding
    def parse_float(matcher = UNDEFINED)
      return Pipe.new { parse_float(_1) }.optional if
        Matcher.undefined?(matcher)

      matcher = Matcher.of(matcher)

      ParseFloatMatcher.new(matcher)
    end

    def float_format
      @float_format ||= ParseFloatMatcher.new(AlwaysMatcher.instance)
    end
  end
end
