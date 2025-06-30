# frozen_string_literal: true

module Matcher
  class Pattern
    class PatternBuilder
      include PatternBuilding
    end

    def self.build(&)
      result = Matcher.with_build_session do
        PatternBuilder.new.instance_exec(&)
      end

      of(result)
    end

    def self.of(recorder)
      expression = Expression.of(recorder)

      new(expression)
    end

    extend Forwardable

    def initialize(expression)
      @expression = expression
    end

    attr_reader :expression

    def_delegator :@expression, :to_s
    def_delegator :@expression, :inspect

    def match(expression, mapping = AstMapping.new)
      result = PatternMatch.new

      catch(:mismatch) do
        match_helper(expression, @expression, mapping, result)

        result.capture(:root, expression, mapping) unless result.include?(:root)

        return result
      end

      nil
    end

    private

    def match_helper(expression, pattern, mapping, result)
      if (hole = get_hole(pattern))
        key = hole.key
        capture = result[key]

        if capture
          throw(:mismatch) if capture.expression != expression
        elsif !hole.match?(expression) { |p| match_helper(expression, p, mapping, result) }
          throw(:mismatch)
        else
          result.capture(key, expression, mapping)
        end
      elsif expression.is_a?(Call)
        throw(:mismatch) unless similar_call?(expression, pattern)

        match_helper(expression.receiver, pattern.receiver, mapping.receiver, result)

        expression.args.each_index do |i|
          match_helper(expression.args[i], pattern.args[i], mapping.args[i], result)
        end

        expression.kwargs.each_key do |k|
          match_helper(expression.kwargs[k], pattern.kwargs[k], mapping.kwargs[k], result)
        end
      elsif expression != pattern
        throw(:mismatch)
      end
    end

    def get_hole(expression)
      return unless expression.is_a?(Constant)

      constant = expression.constant
      constant if constant.is_a?(Hole)
    end

    def similar_call?(expression, pattern)
      expression.class == pattern.class &&
        expression.method == pattern.method &&
        expression.args.length == pattern.args.length &&
        expression.kwargs.size == pattern.kwargs.size &&
        expression.kwargs.keys.sort == pattern.kwargs.keys.sort
    end
  end
end
