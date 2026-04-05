# frozen_string_literal: true

module Matcher
  class ImplySomeMatcher < Base
    def initialize(matchers, else_matcher, count, negated: false)
      check(matchers, else_matcher, count)

      super()

      @matchers = negated ? matchers.map(&:~) : matchers
      @negated_conditions = matchers.map { ~_1.condition }
      @original_matchers = matchers
      @else_matcher = negated ? else_matcher&.~ : else_matcher
      @original_else_matcher = else_matcher
      @count = count
      @negated = negated
    end

    def check(matchers, else_matcher, count)
      raise "matchers must not be empty" if matchers.empty?

      if count != :any && (!count.is_a?(Integer) || count > matchers.length)
        raise "count must be an integer >= matchers.length or :any." \
          "Got #{count.inspect}"
      end

      raise "else cannot be combined with count > 1" if
        else_matcher && count != :any && count != 1

      invalid_matcher = matchers.find { !_1.is_a?(ImplyMatcher) }

      raise "Not an ImplyMatcher: #{invalid_matcher.inspect}" if invalid_matcher
    end

    def negate
      ImplySomeMatcher.new(
        @original_matchers,
        @original_else_matcher,
        @count,
        negated: !@negated,
      )
    end

    def validate(state, &)
      valid_indices = []
      invalid_errors = []

      @matchers.each_with_index do |matcher, i|
        error = yield matcher.condition

        if error.valid?
          valid_indices << i
        else
          invalid_errors << error
        end
      end

      valid_count = valid_indices.length

      if @count == :any ? valid_count > 0 : valid_count == @count
        # case: expected count

        errors = state.errors
        if @negated
          errors.or!
          valid_indices.each do |i|
            error = yield(@matchers[i].matcher)

            if error.valid?
              errors.clear
              break
            end

            errors << error
          end
        else
          valid_indices.each { errors << yield(@matchers[_1].matcher) }
        end
      elsif @count == :any ? valid_count == 0 : valid_count < @count
        # case: too few

        if @else_matcher
          state.errors << yield(@else_matcher)
        elsif !@negated
          state.errors << OrError.from(invalid_errors)
        end
      elsif !@negated
        # case: too many

        negated_conditions = valid_indices.map { @negated_conditions[_1] }
        any_matcher = AnyMatcher.new(negated_conditions)

        state.errors << yield(any_matcher)
      end
    end

    def to_s
      args = @original_matchers.map(&:to_s)

      case @count
      when :any
        method = "imply_any"
      when 1
        method = "imply_one"
      else
        method = "imply_some"
        args << "count: #{@count}"
      end

      args << "else: #{@original_else_matcher}" if @original_else_matcher

      "#{"~" if @negated}#{method}(#{args.join(', ')})"
    end
  end

  module MatcherDsl
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

      return else_matcher || NeverMatcher.instance if matchers.empty?

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

      return else_matcher || NeverMatcher.instance if matchers.empty?

      ImplySomeMatcher.new(matchers, else_matcher, :any)
    end

    def imply_some(*matchers, count:)
      return NeverMatcher.instance if matchers.length < count

      ImplySomeMatcher.new(matchers, nil, count)
    end
  end
end
