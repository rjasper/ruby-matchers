# frozen_string_literal: true

module Matcher
  class ExpressionMatcher < Base
    def self.message_rules
      @message_rules ||= RuleSet.new(MessageRules.rules)
    end

    attr_reader :expression, :negated

    def initialize(expression, negated: false)
      super()

      @expression = expression
      @negated = negated
    end

    def ~
      ExpressionMatcher.new(@expression, negated: !@negated)
    end

    def check(actual)
      expression_values = values.merge(actual:)
      value_tree = @expression.evaluate_tree(expression_values)
      evaluation = value_tree[-1]

      errors << message_factory.create(self, value_tree) if @negated != !evaluation
    rescue CallError => e
      errors << e.message_for_errors unless @negated
    end
    protected :check

    def to_s
      if @negated
        "neg(#{@expression})"
      else
        @expression.to_s
      end
    end

    private

    NEGATED_COMPARISONS = {
      :== => :!=,
      :!= => :==,
      :< => :>=,
      :> => :<=,
      :>= => :<,
      :<= => :>,
      :=~ => :!~,
      :!~ => :=~,
    }.freeze

    def message_factory
      @message_factory ||= ExpressionMatcher.message_rules.apply(@expression)
    end

    def standard_message
      expected.not_if(@negated)
    end

    def expression_message
      expected.namespace(:expression).not_if(@negated)
    end

    def given
      given = {}

      @expression.variables.each do |symbol|
        given[symbol] = symbol == :actual ? actual : values[symbol]
      end

      given
    end

    def decompose_pattern_matching(e_lhs, e_rhs, v_lhs, v_rhs)
      if v_lhs.is_a?(String) && v_rhs.is_a?(Regexp)
        [e_lhs, v_lhs, v_rhs]
      elsif v_lhs.is_a?(Regexp) && v_rhs.is_a?(String)
        [e_rhs, v_rhs, v_lhs]
      else
        nil
      end
    end
  end
end
