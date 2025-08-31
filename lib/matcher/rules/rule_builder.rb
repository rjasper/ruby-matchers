# frozen_string_literal: true

module Matcher
  class RuleBuilder
    include PatternBuilding

    def initialize(rules = [], build_session: Matcher.build_session)
      ExpressionBuilding.init(self, build_session)

      @rules = rules
    end

    attr_reader :rules

    def transform(*patterns, negate: false, &block)
      patterns.map! { pattern_of(_1) }
      @rules << TransformRule.new(patterns, negate, block)

      nil
    end

    def message(*patterns, &block)
      patterns.map! { pattern_of(_1) }
      @rules << MessageRule.new(patterns, block)

      nil
    end
  end
end
