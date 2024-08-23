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
        depth = Matcher.session[:depth]
        errors_stack.push(errors)

        if depth == nil
          Matcher.session[:depth] = 0
        elsif depth > Matcher.max_depth
          errors << "match level too deep: #{depth}"
          return errors
        else
          Matcher.session[:depth] += 1
        end

        check(actual, **values)
      ensure
        errors_stack.pop

        Matcher.session[:depth] -= 1
      end

      errors
    end

    def to_s
      inspect
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
