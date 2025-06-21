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

    def +(matcher)
      matcher = Matcher.of(matcher)

      matchers = if matcher.is_a?(AnyMatcher)
        [self].concat(matcher.matchers)
      else
        [self, matcher]
      end

      AnyMatcher.new(matchers)
    end

    def *(matcher)
      matcher = Matcher.of(matcher)

      matchers = if matcher.is_a?(AllMatcher)
        [self].concat(matcher.matchers)
      else
        [self, matcher]
      end

      AllMatcher.new(matchers)
    end

    def |(matcher)
      matcher = Matcher.of(matcher)

      matchers = if matcher.is_a?(LazyAnyMatcher)
        [self].concat(matcher.matchers)
      else
        [self, matcher]
      end

      LazyAnyMatcher.new(matchers)
    end

    def &(matcher)
      matcher = Matcher.of(matcher)

      matchers = if matcher.is_a?(LazyAllMatcher)
        [self].concat(matcher.matchers)
      else
        [self, matcher]
      end

      LazyAllMatcher.new(matchers)
    end

    def >>(matcher)
      ImplyMatcher.new(self, Matcher.of(matcher))
    end

    StackData = Struct.new(:actual, :vals, :errors)

    def match(actual, values = nil)
      return isolate.match(actual, values) if @thread_safe

      collector = nil

      Matcher.with_session do
        values = merge_values(values)
        frame = StackData.new(actual, values)
        (@stack ||= []) << frame
        collector = new_collector
        frame.errors = collector

        depth = Matcher.session[:depth]

        if depth == nil
          Matcher.session[:depth] = 0
        elsif depth > Matcher.max_depth
          collector << "match level too deep: #{depth}"
          return collector.error
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

      collector.error
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

    def new_collector
      if Matcher.session.fetch(:bind_nested_values, false)
        ErrorCollector.new({ actual:, **values })
      else
        ErrorCollector.new
      end
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
