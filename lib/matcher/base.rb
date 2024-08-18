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

      @errors = errors
      check(actual, **values)
      @errors = nil

      errors
    end

    protected

    def check(actual, **)
      raise NotImplementedError
    end

    attr_reader :errors
  end
end
