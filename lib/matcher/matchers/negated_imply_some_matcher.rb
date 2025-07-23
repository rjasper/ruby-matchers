# frozen_string_literal: true

module Matcher
  class NegatedImplySomeMatcher < Base
    def initialize(matchers, else_matcher, count)
      ImplySomeMatcher.check(matchers, else_matcher, count)

      super()

      @matchers = matchers
      @neg_matchers = matchers.map(&:~)
      @count = count
      @else_matcher = else_matcher
      @neg_else_matcher = @else_matcher&.~
    end

    def ~
      ImplySomeMatcher.new(@matchers, @else_matcher, @count)
    end

    def check(state)
      matchers = @neg_matchers.filter { yield(_1.condition).valid? }

      if matchers.empty?
        state.errors << yield(@neg_else_matcher) if @else_matcher
      elsif @count == :any || matchers.length == @count
        state.errors.or!

        matchers.each do |matcher|
          error = yield(matcher)

          if error.valid?
            state.errors.clear
            break
          end

          state.errors << error
        end
      end
    end

    def to_s
      "~#{self.~}"
    end
  end
end
