# frozen_string_literal: true

module Matcher
  class Base
    def ~
      if respond_to?(:negated)
        negated
      else
        NegatedMatcher.new(self)
      end
    end

    def |(matcher)
      matcher = Matcher.of(matcher)

      AnyMatcher.new([self, matcher])
    end

    def &(matcher)
      matcher = Matcher.of(matcher)

      AllMatcher.new([self, matcher])
    end

    def get_actual(actual:, **)
      actual
    end

    def match(actual = NULL, **)
      errors = Errors::Collector.new

      Matcher.with_session do
        depth = Matcher.session[:depth]
        errors_stack.push(errors)

        if depth == nil
          Matcher.session[:depth] = 0
        elsif depth > Matcher.max_depth
          errors << "match level too deep: #{depth}"
          return errors.node
        else
          Matcher.session[:depth] += 1
        end

        if actual.equal?(NULL)
          check(**)
        else
          check(**, actual:)
        end
      ensure
        errors_stack.pop

        Matcher.session[:depth] -= 1
      end

      errors.node
    end

    def inspect
      to_s
    end

    protected

    def check(**)
      raise NotImplementedError
    end

    def errors_stack
      session[:errors_stack] ||= []
    end

    def errors
      errors_stack.last
    end

    def session(key = nil)
      Matcher.session[key || object_id] ||= {}
    end

    def self.session
      Matcher.session[self] ||= {}
    end

    def class_session
      self.class.session
    end
  end
end
