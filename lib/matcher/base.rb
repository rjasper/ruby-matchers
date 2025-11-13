# frozen_string_literal: true

module Matcher
  class Base
    include NoExpression
    include NoKey

    ##
    # Negates this matcher
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

    ##
    # Combines with matcher to AnyMatcher
    # @param matcher
    # @return [AnyMatcher]
    # @see MatcherBuilding#any
    def +(matcher)
      matcher = Matcher.cache(matcher)

      matchers = if matcher.is_a?(AnyMatcher)
        [self].concat(matcher.matchers)
      else
        [self, matcher]
      end

      AnyMatcher.new(matchers)
    end

    ##
    # Combines with matcher to AllMatcher
    # @param matcher
    # @return [AllMatcher]
    # @see MatcherBuilding#all
    def *(matcher)
      matcher = Matcher.cache(matcher)

      matchers = if matcher.is_a?(AllMatcher)
        [self].concat(matcher.matchers)
      else
        [self, matcher]
      end

      AllMatcher.new(matchers)
    end

    ##
    # Combines with matcher to LazyAnyMatcher
    # @param matcher
    # @return [LazyAnyMatcher]
    # @see MatcherBuilding#lazy_any
    def |(matcher)
      matcher = Matcher.cache(matcher)

      matchers = if matcher.is_a?(LazyAnyMatcher)
        [self].concat(matcher.matchers)
      else
        [self, matcher]
      end

      LazyAnyMatcher.new(matchers)
    end

    ##
    # Combines with matcher to LazyAllMatcher
    # @param matcher
    # @return [LazyAllMatcher]
    # @see MatcherBuilding#lazy_all
    def &(matcher)
      matcher = Matcher.cache(matcher)

      matchers = if matcher.is_a?(LazyAllMatcher)
        [self].concat(matcher.matchers)
      else
        [self, matcher]
      end

      LazyAllMatcher.new(matchers)
    end

    ##
    # Implies another matcher
    # @param matcher
    # @return [ImplyMatcher]
    # @see MatcherBuilding#imply
    def >>(matcher)
      ImplyMatcher.new(self, Matcher.cache(matcher))
    end

    StackData = Struct.new(:actual, :vals, :errors)

    ##
    # Returns +true+ if actual matches, +false+ otherwise
    # @example
    #   Matcher.build { Integer }.match?(42) # => true
    # @param actual the value to match against
    # @param ** values
    # @return [Boolean]
    def match?(actual, **)
      match_helper(true, actual:, **).valid?
    end
    alias === match?

    ##
    # Returns an error tree describing all mismatches
    # @example
    #   errors = Matcher.build { Integer }.match("foo")
    #   puts Matcher::Reporter.report(errors)
    #   # > root: expected a kind of Integer but got "foo"
    # @param actual the value to match against
    # @param ** values
    # @return [Error]
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

    ##
    # Stores information for this matcher instance during match time.
    def session(key = object_id)
      Matcher.session[key] ||= {}
    end

    ##
    # Stores information for this matcher class during match time.
    def self.session
      Matcher.session[self] ||= {}
    end

    ##
    # Stores information for this matcher's class during match time.
    def class_session
      self.class.session
    end
  end
end
