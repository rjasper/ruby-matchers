# frozen_string_literal: true

module Matcher
  module RuleBuilding
    def transform(*patterns, negate: false, &block)
      patterns.map! { Pattern.of(_1) }
      @rules << TransformRule.new(patterns, negate, block)

      nil
    end

    def message(*patterns, &block)
      patterns.map! { Pattern.of(_1) }
      @rules << MessageRule.new(patterns, block)

      nil
    end
  end
end
