# frozen_string_literal: true

module Matcher
  class Base
    include NoExpression

    def ~
      matcher_cache = MatcherCache.current

      return negate unless matcher_cache

      cache = (matcher_cache.negated_matchers ||= {}.compare_by_identity)
      negated = cache[self]

      unless negated
        negated = negate
        cache[self] = negated
        cache[negated] = self
      end

      negated
    end

    def negate
      NegatedMatcher.new(self)
    end

    def +(matcher)
      matcher = Matcher.cache(matcher)

      matchers = if matcher.is_a?(AnyMatcher)
        [self].concat(matcher.matchers)
      else
        [self, matcher]
      end

      AnyMatcher.new(matchers)
    end

    def *(matcher)
      matcher = Matcher.cache(matcher)

      matchers = if matcher.is_a?(AllMatcher)
        [self].concat(matcher.matchers)
      else
        [self, matcher]
      end

      AllMatcher.new(matchers)
    end

    def |(matcher)
      matcher = Matcher.cache(matcher)

      matchers = if matcher.is_a?(LazyAnyMatcher)
        [self].concat(matcher.matchers)
      else
        [self, matcher]
      end

      LazyAnyMatcher.new(matchers)
    end

    def &(matcher)
      matcher = Matcher.cache(matcher)

      matchers = if matcher.is_a?(LazyAllMatcher)
        [self].concat(matcher.matchers)
      else
        [self, matcher]
      end

      LazyAllMatcher.new(matchers)
    end

    def >>(matcher)
      ImplyMatcher.new(self, Matcher.cache(matcher))
    end

    StackData = Struct.new(:actual, :vals, :errors)

    def match(actual, **)
      hash_stack = HashStack.new

      invoke = lambda do |matcher, act = UNDEFINED, **kwargs|
        state = State.new(hash_stack)
        kwargs[:actual] = act unless Matcher.undefined?(act)

        if kwargs.empty?
          matcher.check(state, &invoke)
        else
          hash_stack.push(kwargs)
          matcher.check(state, &invoke)
          hash_stack.pop(kwargs)
        end

        state.result
      end

      Matcher.with_session do
        invoke.call(self, actual:, **)
      end
    end

    def check(actual)
      raise NotImplementedError
    end

    def inspect
      to_s
    end

    protected

    def session(key = object_id)
      Matcher.session[key] ||= {}
    end

    def self.session
      Matcher.session[self] ||= {}
    end

    def class_session
      self.class.session
    end
  end
end
