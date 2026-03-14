# frozen_string_literal: true

module Matcher
  class Base
    include NoExpression
    include NoKey

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
    protected :negate

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

    def match?(actual, **)
      match_helper(true, actual:, **).valid?
    end
    alias === match?

    def match(actual, **)
      match_helper(false, actual:, **)
    end

    def match_helper(boolean, **)
      hash_stack = HashStack.new

      invoke = lambda do |matcher, act = UNDEFINED, **kwargs|
        state = State.new(hash_stack, boolean:)
        kwargs[:actual] = act unless Matcher.undefined?(act)

        hash_stack.push(kwargs)

        catch(:mismatch) do
          matcher.validate(state, &invoke)
        end

        hash_stack.pop(kwargs)

        state.result
      end

      Matcher.with_session do
        invoke.call(self, **)
      end
    end
    private :match_helper

    def validate(state)
      raise NotImplementedError
    end
    protected :validate

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
