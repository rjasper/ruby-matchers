# frozen_string_literal: true

module Matcher
  class Base
    def initialize
      @session_key = object_id
      @thread_safe = Matcher.build_session&.[](:thread_safe) == true
    end

    def actual
      @stack&.last&.actual
    end

    def values
      @stack&.last&.vals
    end

    def ~
      NegatedMatcher.new(self)
    end

    def |(matcher)
      matcher = Matcher.of(matcher)

      matchers = if matcher.is_a?(AnyMatcher)
        [self].concat(matcher.matchers)
      else
        [self, matcher]
      end

      AnyMatcher.new(matchers)
    end

    def &(matcher)
      matcher = Matcher.of(matcher)

      matchers = if matcher.is_a?(AllMatcher)
        [self].concat(matcher.matchers)
      else
        [self, matcher]
      end

      AllMatcher.new(matchers)
    end

    StackData = Struct.new(:actual, :vals, :errors)

    def match(actual, values = nil)
      return isolate.match(actual, values) if @thread_safe

      errors = ErrorCollector.new
      (@stack ||= []) << StackData.new(actual, merge_values(values), errors)

      Matcher.with_session do
        depth = Matcher.session[:depth]

        if depth == nil
          Matcher.session[:depth] = 0
        elsif depth > Matcher.max_depth
          errors << "match level too deep: #{depth}"
          return errors.node
        else
          Matcher.session[:depth] += 1
        end

        check(actual) do |matcher, act = actual, **kwargs|
          matcher.match(act, merge_values(kwargs))
        end
      ensure
        if @stack.length > 1
          @stack.pop
        else
          @stack = nil
        end

        Matcher.session[:depth] -= 1
      end

      errors.node
    end

    def inspect
      to_s
    end

    protected

    attr_writer :session_key, :thread_safe

    def check(actual)
      raise NotImplementedError
    end

    def errors
      @stack.last.errors
    end

    def report(actual = self.actual)
      StandardMessageBuilder.new(false, actual)
    end

    def expected(actual = self.actual)
      StandardMessageBuilder.new(true, actual)
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

    def merge_values(values)
      previous = @stack&.last&.vals

      if !previous
        values || {}
      elsif previous.empty?
        values || previous
      elsif !values || values.empty?
        previous
      else
        previous.merge(values)
      end
    end
  end
end
