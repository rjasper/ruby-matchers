# frozen_string_literal: true

module Matcher
  class ParseIntegerMatcher < Base
    def initialize(matcher, base: 0, negated: false)
      super()

      @matcher = negated ? ~matcher : matcher
      @original_matcher = matcher
      @base = base
      @negated = negated
    end

    def negate
      ParseIntegerMatcher.new(@original_matcher, base: @base, negated: !@negated)
    end

    def validate(state, &)
      actual = state.actual

      unless actual.is_a?(String)
        state.errors << state.expected.kind_of(String) unless @negated
        return
      end

      value = Integer(actual)

      if @matcher.is_a?(NeverMatcher)
        state.errors << state.expected.not.valid_format(:integer)
        return
      end

      result = yield(@matcher, value)

      return if result.valid?

      integer_of = Call.new(Constant.new(Kernel), :Integer, [Variable.actual])
      state.errors[integer_of] << result
    rescue ArgumentError
      state.errors << state.expected.valid_format(:integer) unless @negated
    end

    def to_s
      prefix = @negated ? "~" : ""

      if @original_matcher.is_a?(AlwaysMatcher)
        args = @base == 0 ? "" : "(base: #{@base})"
        return "#{prefix}integer_format#{args}"
      end

      base_arg = @base == 0 ? "" : ", base: #{@base}"

      "#{'~' if @negated}parse_integer(#{@original_matcher}#{base_arg})"
    end
  end

  module MatcherBuilding
    ##
    # Parses integer and matches with given matcher
    # @example
    #   # matches "7"
    #   parse_integer(_.odd?)
    #   # alternatively:
    #   parse_integer ^ (_.odd?)
    #   # without matcher matches any integer string
    #   parse_integer
    # @overload parse_integer(matcher, base: 0)
    #   @param matcher [Base]
    #   @param base [Integer]
    #   @return [ParseIntegerMatcher]
    # @overload parse_integer(base: 0)
    #   @return [OptionalChain<ParseIntegerMatcher>]
    # @see #integer_format
    def parse_integer(matcher = UNDEFINED, base: 0)
      return Chain.new { parse_integer(_1, base:) }.optional if
        Matcher.undefined?(matcher)

      matcher = matcher_of(matcher)

      ParseIntegerMatcher.new(matcher, base:)
    end

    ##
    # Matches integer strings
    # @example
    #   # matches { payload: "42" }
    #   { payload: integer_format }
    # @param base [Integer]
    # @return [ParseIntegerMatcher]
    def integer_format(base: 0)
      if base == 0
        @integer_format ||= ParseIntegerMatcher.new(AlwaysMatcher.instance, base:)
      else
        ParseIntegerMatcher.new(AlwaysMatcher.instance, base:)
      end
    end
  end
end
