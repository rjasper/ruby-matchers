# frozen_string_literal: true

module Matcher
  class EqualMatcher < Base
    def initialize(value, negated: false)
      super()

      @value = value
      @negated = negated
    end

    def ~
      EqualMatcher.new(@value, negated: !@negated)
    end

    def check(state)
      value = @value.is_a?(Expression) ? @value.evaluate(state.values) : @value

      if @negated
        errors = state.errors.or!

        catch(:valid) do
          negated_check_helper(errors, value, state.actual)

          # prevent clearing errors
          return
        end

        # caught :valid
        errors.clear
      else
        check_helper(state.errors, value, state.actual)
      end
    end

    def to_s
      case @value
      when *CASE_EQUALITY_CLASSES
        "#{'~' if @negated}equal(#{@value.inspect})"
      else
        @negated ? "neg(#{@value.inspect})" : @value.inspect
      end
    end

    private

    def check_helper(errors, exp, act)
      case exp
      when Array
        check_array(errors, exp, act)
      when Hash
        check_hash(errors, exp, act)
      when Set
        check_set(errors, exp, act)
      else
        errors << expected(act).not_if(@negated).equal(exp) if
          @negated ^ (act != exp)
      end
    end

    def check_array(errors, exp, act)
      unless act.is_a?(Array)
        errors << expected(act).kind_of(Array)
        return
      end

      errors << expected(act).length_of(exp.length, act.length) if
        exp.length != act.length

      [exp.length, act.length].min.times do |i|
        check_helper(errors[i], exp[i], act[i])
      end
    end

    def check_hash(errors, exp, act)
      unless act.is_a?(Hash)
        errors << expected(act).kind_of(Hash)
        return
      end

      (act.keys - exp.keys).each do |key|
        errors[key] << expected(act).not.having_key(key)
      end

      exp.each do |key, exp_value|
        act_value = act[key]

        if act_value.nil? && !act.key?(key)
          errors << expected(act).having_key(key)
        else
          check_helper(errors[key], exp_value, act_value)
        end
      end
    end

    def check_set(errors, exp, act)
      unless act.is_a?(Set)
        errors << expected(act).kind_of(Set)
        return
      end

      (exp - act).each do |item|
        errors << expected(act).including(item)
      end

      (act - exp).each do |item|
        errors << expected(act).not.including(item)
      end
    end

    def negated_check_helper(errors, exp, act)
      case exp
      when Array
        negated_check_array(errors, exp, act)
      when Hash
        negated_check_hash(errors, exp, act)
      when Set
        negated_check_set(errors, exp, act)
      else
        if act == exp
          errors << expected(act).not.equal(exp)
        else
          throw(:valid)
        end
      end
    end

    def negated_check_array(errors, exp, act)
      throw(:valid) if !act.is_a?(Array) || exp.length != act.length

      exp.length.times do |i|
        negated_check_helper(errors[i], exp[i], act[i])
      end
    end

    def negated_check_hash(errors, exp, act)
      throw(:valid) unless act.is_a?(Hash)

      exp_keys_set = Set.new(exp.keys)
      throw(:valid) unless act.keys.all? { exp_keys_set.include?(_1) }

      exp.each do |key, exp_value|
        act_value = act[key]

        if act_value.nil? && !act.key?(key)
          throw(:valid)
        else
          negated_check_helper(errors[key], exp_value, act_value)
        end
      end
    end

    def negated_check_set(errors, exp, act)
      throw(:valid) if !act.is_a?(Set) || act != exp

      exp.each do |item|
        errors << expected(act).not.including(item)
      end
    end
  end

  module MatcherBuilding
    def equal(value)
      value = Expression.of(value)
      value = value.value if value.is_a?(Constant)

      EqualMatcher.new(value)
    end
  end
end
