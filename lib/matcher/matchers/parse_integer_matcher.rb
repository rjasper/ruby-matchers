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

    def ~
      ParseIntegerMatcher.new(@original_matcher, base: @base, negated: !@negated)
    end

    def check(state, &)
      actual = state.actual

      unless actual.is_a?(String)
        state.errors << expected.kind_of(String) unless @negated
        return
      end

      value = Integer(actual)
      result = yield(@matcher, value)

      return if result.valid?

      integer_of = Call.new(Constant.new(Kernel), :Integer, [Variable.actual])
      state.errors[integer_of] << result
    rescue ArgumentError
      state.errors << expected.valid_format(:integer) unless @negated
    end

    def to_s
      base_arg = @base == 0 ? '' : ", base: #{@base}"

      "#{'~' if @negated}parse_integer(#{@original_matcher}#{base_arg})"
    end
  end

  module MatcherBuilding
    def parse_integer(matcher = UNDEFINED, base: 0)
      return Pipe.new { parse_integer(_1, base:) } if Matcher.undefined?(matcher)

      matcher = Matcher.of(matcher)

      ParseIntegerMatcher.new(matcher, base:)
    end
  end
end
