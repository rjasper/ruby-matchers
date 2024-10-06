# frozen_string_literal: true

module Matcher
  class Base
    def initialize
      @session_key = object_id
      @thread_safe = Matcher.build_session&.[](:thread_safe) == true
    end

    def ~
      NegatedMatcher.new(self)
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
      return isolate.match(actual, **) if @thread_safe

      errors = Errors::Collector.new

      Matcher.with_session do
        depth = Matcher.session[:depth]
        (@errors_stack ||= []).push(errors)

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
        @errors_stack.pop
        @errors_stack = nil if @errors_stack.empty?

        Matcher.session[:depth] -= 1
      end

      errors.node
    end

    def inspect
      to_s
    end

    protected

    attr_writer :session_key, :thread_safe

    def check(**)
      raise NotImplementedError
    end

    def errors
      @errors_stack.last
    end

    def session(key = nil)
      Matcher.session[key || @session_key] ||= {}
    end

    def self.session
      Matcher.session[self] ||= {}
    end

    def class_session
      self.class.session
    end

    private

    def isolate
      klone = clone
      klone.session_key = @session_key
      klone.thread_safe = false

      klone
    end
  end
end
