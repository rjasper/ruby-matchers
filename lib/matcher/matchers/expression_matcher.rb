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

    def check(state)
      value_tree = @expression.evaluate_tree(state.values)
      evaluation = value_tree[-1]

      state.errors << message_factory.create(self, value_tree) if @negated != !evaluation
    rescue CallError => e
      state.errors << e.message_for_errors unless @negated
    end

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
  end
end
