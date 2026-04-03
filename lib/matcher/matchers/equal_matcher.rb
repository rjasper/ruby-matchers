# frozen_string_literal: true

module Matcher
  class EqualMatcher < Base
    CACHEABLE_CLASSES = [
      NilClass,
      FalseClass,
      TrueClass,
      Integer,
      Float,
      Symbol,
      String,
      Regexp,
      Module,
    ].freeze

    def self.cache(value, matcher_cache = MatcherCache.current)
      return new(value) if !matcher_cache ||
        !CACHEABLE_CLASSES.include?(value) ||
        value.is_a?(String) && !value.frozen?

      (matcher_cache.equal_matchers ||= {})[value] ||= new(value)
    end

    def initialize(value, negated: false)
      super()

      @value = value
      @negated = negated
    end

    def negate
      EqualMatcher.new(@value, negated: !@negated)
    end

    def validate(state)
      value = @value.is_a?(Expression) ? @value.evaluate(state.values) : @value

      if @negated
        errors = state.errors.or!

        catch(:valid) do
          validate_negated_helper(state, errors, value, state.actual)

          # prevent clearing errors
          return
        end

        # caught :valid
        errors.clear
      else
        validate_helper(state, state.errors, value, state.actual)
      end
    end

    IMPLICIT_MATCHER_CLASSES =
      [Module, Range, Regexp, Hash, Array, Expression].freeze

    def to_s
      if IMPLICIT_MATCHER_CLASSES.any? { @value.is_a?(_1) }
        "#{'~' if @negated}equal(#{@value.inspect})"
      else
        @negated ? "neg(#{@value.inspect})" : @value.inspect
      end
    end

    private

    def validate_helper(state, errors, exp, act)
      case exp
      when Array
        validate_array(state, errors, exp, act)
      when Hash
        validate_hash(state, errors, exp, act)
      when Set
        validate_set(state, errors, exp, act)
      else
        errors << state.expected(act).not_if(@negated).equal(exp) if
          @negated ^ (act != exp)
      end
    end

    def validate_array(state, errors, exp, act)
      unless act.is_a?(Array)
        errors << state.expected(act).kind_of(Array)
        return
      end

      errors << state.expected(act).length_of(exp.length, act.length) if
        exp.length != act.length

      [exp.length, act.length].min.times do |i|
        validate_helper(state, errors[i], exp[i], act[i])
      end
    end

    def validate_hash(state, errors, exp, act)
      unless act.is_a?(Hash)
        errors << state.expected(act).kind_of(Hash)
        return
      end

      (act.keys - exp.keys).each do |key|
        errors[key] << state.expected(act).not.having_key(key)
      end

      exp.each do |key, exp_value|
        act_value = act[key]

        if act_value.nil? && !act.key?(key)
          errors << state.expected(act).having_key(key)
        else
          validate_helper(state, errors[key], exp_value, act_value)
        end
      end
    end

    def validate_set(state, errors, exp, act)
      unless act.is_a?(Set)
        errors << state.expected(act).kind_of(Set)
        return
      end

      (exp - act).each do |item|
        errors << state.expected(act).including(item)
      end

      (act - exp).each do |item|
        errors << state.expected(act).not.including(item)
      end
    end

    def validate_negated_helper(state, errors, exp, act)
      case exp
      when Array
        validate_array_negated(state, errors, exp, act)
      when Hash
        validate_hash_negated(state, errors, exp, act)
      when Set
        validate_set_negated(state, errors, exp, act)
      else
        if act == exp
          errors << state.expected(act).not.equal(exp)
        else
          throw(:valid)
        end
      end
    end

    def validate_array_negated(state, errors, exp, act)
      throw(:valid) if !act.is_a?(Array) || exp.length != act.length

      exp.length.times do |i|
        validate_negated_helper(state, errors[i], exp[i], act[i])
      end
    end

    def validate_hash_negated(state, errors, exp, act)
      throw(:valid) unless act.is_a?(Hash)

      exp_keys_set = Set.new(exp.keys)
      throw(:valid) unless act.keys.all? { exp_keys_set.include?(_1) }

      exp.each do |key, exp_value|
        act_value = act[key]

        if act_value.nil? && !act.key?(key)
          throw(:valid)
        else
          validate_negated_helper(state, errors[key], exp_value, act_value)
        end
      end
    end

    def validate_set_negated(state, errors, exp, act)
      throw(:valid) if !act.is_a?(Set) || act != exp

      exp.each do |item|
        errors << state.expected(act).not.including(item)
      end
    end
  end

  module MatcherBuilding
    ##
    # Matches equal value
    # @example
    #   # matches String but not "foo"
    #   equal(String)
    # @param value
    # @return [EqualMatcher]
    def equal(value)
      value = expression_or_value(value)

      EqualMatcher.cache(value, @matcher_cache)
    end
  end
end
