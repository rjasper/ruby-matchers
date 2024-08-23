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

      Matcher.with_session do
        errors_stack.push(errors)
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
      session[:errors_stack] ||= []
    end

    def errors
      errors_stack.last
    end

    def session
      Matcher.session[object_id] ||= {}
    end

    def self.session
      Matcher.session[self] ||= {}
    end

    def class_session
      self.class.session
    end
  end
end
