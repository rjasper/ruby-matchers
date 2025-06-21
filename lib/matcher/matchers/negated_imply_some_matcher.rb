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

    def check(_actual)
      matchers = @neg_matchers.filter { yield(_1.condition).valid? }

      if matchers.empty?
        errors << yield(@neg_else_matcher) if @else_matcher
      elsif @count == :any || matchers.length == @count
        errors.or!

        matchers.each do |matcher|
          error = yield(matcher)

          if error.valid?
            errors.clear
            break
          end

          errors << error
        end
      end
    end
    protected :check

    def to_s
      "~#{self.~}"
    end
  end
end
