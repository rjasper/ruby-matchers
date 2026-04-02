# frozen_string_literal: true

module Matcher
  class ParseFloatMatcher < Base
    def initialize(matcher, negated: false)
      super()

      @matcher = negated ? ~matcher : matcher
      @original_matcher = matcher
      @negated = negated
    end

    def negate
      ParseFloatMatcher.new(@original_matcher, negated: !@negated)
    end

    def validate(state, &)
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
      prefix = @negated ? "~" : ""

      return "#{prefix}float_format" if @original_matcher.is_a?(AlwaysMatcher)

      "#{prefix}parse_float(#{@original_matcher})"
    end
  end

  module MatcherBuilding
    ##
    # Parses float and matches with given matcher.
    # @example
    #   # matches "1.0"
    #   parse_float(_ > 0.0)
    #   # alternatively:
    #   parse_float ^ (_ > 0.0)
    #   # without matcher matches any float string
    #   parse_float
    # @overload parse_float(matcher)
    #   @param matcher [Base]
    #   @return [ParseFloatMatcher]
    # @overload parse_float
    #   @return [OptionalChain<ParseFloatMatcher>]
    # @see #float_format
    def parse_float(matcher = UNDEFINED)
      return Chain.new { parse_float(_1) }.optional if
        Matcher.undefined?(matcher)

      matcher = matcher_of(matcher)

      ParseFloatMatcher.new(matcher)
    end

    ##
    # Matches float strings
    # @example
    #   # matches { payload: "1.5" }
    #   { payload: float_format }
    # @return [ParseFloatMatcher]
    def float_format
      @float_format ||= ParseFloatMatcher.new(AlwaysMatcher.instance)
    end
  end
end
