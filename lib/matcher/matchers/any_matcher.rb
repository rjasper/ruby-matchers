# frozen_string_literal: true

module Matcher
  class AnyMatcher < Base
    def initialize(matchers)
      super()

      @matchers = matchers
    end

    def |(matcher)
      matcher = Matcher.of(matcher)

      AnyMatcher.new(@matchers + [matcher])
    end

    def negated
      AllMatcher.new(@matchers.map(&:~))
    end

    def check(**)
      sub_errors = @matchers.map do |matcher|
        sub_error = matcher.match(**)

        return if sub_error.valid?

        sub_error
      end

      errors << Errors::Or.from(sub_errors)
    end
    protected :check

    def inspect
      "any(#{@matchers.map(&:inspect).join(', ')})"
    end
  end
end
