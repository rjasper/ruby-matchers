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

    def match(actual)
      errors = Errors.new

      @errors = errors
      check(actual)
      @errors = nil

      errors
    end

    def check(actual)
      raise NotImplementedError
    end

    protected

    attr_reader :errors
  end
end
