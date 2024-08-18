# frozen_string_literal: true

module Matcher
  class Base
    def |(matcher)
      matcher = Matcher.of(matcher)

      AnyMatcher.new([self, matcher])
    end

    def &(matcher)
      matcher = Matcher.of(matcher)

      AllMatcher.new([self, matcher])
    end

    def match(actual, **values)
      errors = Errors.new
      errors_stack.push(errors)

      begin
        check(actual, **values)
      ensure
        errors_stack.pop
      end

      errors
    end

    protected

    def check(actual, **)
      raise NotImplementedError
    end

    def errors_stack
      @errors_stack ||= []
    end

    def errors
      errors_stack.last
    end
  end
end
