# frozen_string_literal: true

module Matcher
  class ImplyMatcher < Base
    attr_reader :condition, :matcher

    def initialize(condition, matcher, negated: false)
      super()

      @condition = condition
      @matcher = negated ? ~matcher : matcher
      @original_matcher = matcher
      @negated = negated
    end

    def ~
      ImplyMatcher.new(@condition, @original_matcher, negated: !@negated)
    end

    def check(state, &)
      return negated_check(state, &) if @negated

      return unless yield(@condition).valid?

      state.errors << yield(@matcher)
    end

    def to_s
      "#{'~' if @negated}imply(#{@condition}, #{@original_matcher})"
    end

    private

    def negated_check(state)
      condition_errors = yield @condition

      state.errors << if condition_errors.valid?
        yield(@matcher)
      else
        condition_errors
      end
    end
  end

  module MatcherBuilding
    def imply(condition, matcher = UNDEFINED)
      return Pipe.new { imply(condition, _1) } if Matcher.undefined?(matcher)

      condition = Matcher.of(condition)
      matcher = Matcher.of(matcher)

      ImplyMatcher.new(condition, matcher)
    end
  end
end
