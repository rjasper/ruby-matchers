# frozen_string_literal: true

module Matcher
  class RuleSet
    def initialize(rules = [], &)
      @rules = rules

      configure(&) if block_given?
    end

    def configure(&)
      builder = RuleBuilder.new(@rules)
      builder.instance_exec(&)

      self
    end

    def apply(expression)
      cur = expression
      mapping = AstMapping.new
      result = nil
      negate = false

      while (rule, match = find_rule(cur, mapping))
        result = rule.apply(match)

        if rule.is_a?(MessageRule)
          result.negate! if negate

          return result
        end

        cur = result.expression
        mapping = result.mapping
        negate = !negate if rule.negate?
      end

      result
    end

    private

    def find_rule(expression, mapping)
      @rules.each do |rule|
        rule.patterns.each do |pattern|
          match = pattern.match(expression, mapping)

          return [rule, match] if match
        end
      end

      nil
    end
  end
end
