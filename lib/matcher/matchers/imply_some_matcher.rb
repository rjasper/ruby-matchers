# frozen_string_literal: true

module Matcher
  class ImplySomeMatcher < Base
    def self.check(matchers, else_matcher, count)
      raise "count must be a positive integer or :any. Got #{count.inspect}" if
        count != :any && (!count.is_a?(Integer) || count <= 0)

      raise "else cannot be combined with count > 1" if
        else_matcher && count != :any && count != 1

      invalid_matcher = matchers.find { !_1.is_a?(ImplyMatcher) }

      raise "Not an ImplyMatcher: #{invalid_matcher.inspect}" if invalid_matcher
    end

    def initialize(matchers, else_matcher, count)
      ImplySomeMatcher.check(matchers, else_matcher, count)

      super()

      @matchers = matchers
      @else_matcher = else_matcher
      @count = count
    end

    def negate
      NegatedImplySomeMatcher.new(@matchers, @else_matcher, @count)
    end

    def validate(state)
      errors = state.errors
      matchers = @matchers.filter { yield(_1.condition).valid? }

      if matchers.empty?
        errors << if @else_matcher
          yield @else_matcher
        else
          state.report.namespace(:imply_some)
            .no_condition_satisfied(@matchers.map(&:condition), @count)
        end

        return
      elsif @count != :any && matchers.length != @count
        errors << state.report.namespace(:imply_some)
          .x_conditions_satisfied(matchers.map(&:condition), @count)
      end

      matchers.each { errors << yield(_1.matcher) }
    end

    def to_s
      args = @matchers.map(&:to_s)

      case @count
      when :any
        method = "imply_any"
      when 1
        method = "imply_one"
      else
        method = "imply_some"
        args << "count: #{@count}"
      end

      args << "else: #{@else_matcher}" if @else_matcher

      "#{method}(#{args.join(', ')})"
    end
  end

  module MatcherBuilding
    ##
    # Matches exactly one implied matcher
    # @example
    #   # Strings should be lower case and integers positive. But it should
    #   # either be a string or an integer.
    #   # matches "foo" and 1 but not "BAR", -1, or nil
    #   imply_one(
    #     imply(String, _ == _.downcase),
    #     imply(Integer, _.positive?),
    #   )
    # @param matchers [ImplyMatcher]
    # @param else [Base] if no condition passed match against +else+ matcher.
    # @return [ImplySomeMatcher]
    # @see #imply
    def imply_one(*matchers, else: UNDEFINED)
      els = { else: }[:else]
      else_matcher = Matcher.undefined?(els) ? nil : matcher_of(els)

      ImplySomeMatcher.new(matchers, else_matcher, 1)
    end

    ##
    # Matches at least one implied matcher
    # @example
    #   # matches 9, 12, 40 but not 8, 21, 15.5
    #   imply_any(
    #     imply(_.even?, _ > 10),
    #     imply(_ % 3 == 0, _ < 20),
    #   )
    # @param matchers [ImplyMatcher]
    # @param else [Base] if no condition passed match against +else+ matcher.
    # @return [ImplySomeMatcher]
    # @see #imply
    def imply_any(*matchers, else: UNDEFINED)
      els = { else: }[:else]
      else_matcher = Matcher.undefined?(els) ? nil : matcher_of(els)

      ImplySomeMatcher.new(matchers, else_matcher, :any)
    end

    def imply_some(*matchers, count:)
      ImplySomeMatcher.new(matchers, nil, count)
    end
  end
end
