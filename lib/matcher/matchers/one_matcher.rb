# frozen_string_literal: true

module Matcher
  class OneMatcher < Base
    def initialize(matchers, negated: false)
      super()

      @matchers = matchers
      @negated = negated
    end

    def ~
      OneMatcher.new(@matchers, negated: !@negated)
    end

    def check(state)
      valid_matchers = []
      invalid_errors = []

      @matchers.each do |matcher|
        error = yield matcher

        if error.valid?
          valid_matchers << matcher
        else
          invalid_errors << error
        end
      end

      if @negated
        state.errors << yield(~valid_matchers[0]) if valid_matchers.length == 1
      else
        if valid_matchers.length == 0
          state.errors << OrError.from(invalid_errors)
        elsif valid_matchers.length > 1
          negated_matchers = valid_matchers.map(&:~)
          any_matcher = AnyMatcher.new(negated_matchers)

          state.errors << yield(any_matcher)
        end
      end
    end

    def to_s
      "#{'~' if @negated}one(#{@matchers.map(&:to_s).join(', ')})"
    end
  end

  module MatcherBuilding
    def one(*matchers)
      matchers = matchers.map { of(_1) }

      case matchers.count
      when 0
        NeverMatcher.instance
      when 1
        matchers[0]
      else
        OneMatcher.new(matchers)
      end
    end
  end
end
