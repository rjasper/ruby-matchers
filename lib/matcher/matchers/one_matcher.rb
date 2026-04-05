# frozen_string_literal: true

module Matcher
  class OneMatcher < Base
    def initialize(matchers, negated: false)
      super()

      @matchers = matchers
      @negated_matchers = matchers.map(&:~)
      @negated = negated
    end

    def negate
      OneMatcher.new(@matchers, negated: !@negated)
    end

    def validate(state)
      valid_indices = []
      invalid_errors = []

      @matchers.each_with_index do |matcher, i|
        error = yield matcher

        if error.valid?
          valid_indices << i
        else
          invalid_errors << error
        end
      end

      if @negated
        if valid_indices.length == 1
          negated_matcher = @negated_matchers[valid_indices[0]]
          state.errors << yield(negated_matcher)
        end
      elsif valid_indices.length == 0
        state.errors << OrError.from(invalid_errors)
      elsif valid_indices.length > 1
        negated_matchers = valid_indices.map { @negated_matchers[_1] }
        any_matcher = AnyMatcher.new(negated_matchers)

        state.errors << yield(any_matcher)
      end
    end

    def to_s
      "#{'~' if @negated}one(#{@matchers.join(', ')})"
    end
  end

  module MatcherDsl
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
