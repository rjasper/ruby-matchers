# frozen_string_literal: true

module Matcher
  class OneMatcher < Base
    def initialize(matchers, negated: false)
      super()

      @matchers = matchers
      @negated = negated
    end

    def negate
      OneMatcher.new(@matchers, negated: !@negated)
    end

    def validate(state)
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
      elsif valid_matchers.length == 0
        state.errors << OrError.from(invalid_errors)
      elsif valid_matchers.length > 1
        negated_matchers = valid_matchers.map(&:~)
        any_matcher = AnyMatcher.new(negated_matchers)

        state.errors << yield(any_matcher)
      end
    end

    def to_s
      "#{'~' if @negated}one(#{@matchers.join(', ')})"
    end
  end

  module MatcherBuilding
    ##
    # Matches exactly one matcher
    # @example
    #   # matches [1] and [2] but not [] or [1, 2]
    #   one(_.include?(1), _.include?(2))
    # @param matchers [Array<Base>]
    # @return [OneMatcher]
    def one(*matchers)
      matchers = matchers.map { matcher_of(_1) }

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
