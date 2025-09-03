# frozen_string_literal: true

module Matcher
  class ExpressionMatcher < Base
    def self.cache(value, matcher_cache = MatcherCache.current, expression_cache = ExpressionCache.current)
      return new(value) unless matcher_cache

      cache = (matcher_cache.expression_matchers ||= {})
      label = expression_cache.label(value)

      cache[label] ||= new(value)
    end

    def self.message_rules
      @message_rules ||= RuleSet.new
    end

    attr_reader :expression, :negated

    def initialize(expression, negated: false)
      super()

      @expression = expression
      @negated = negated
    end

    def negate
      ExpressionMatcher.new(@expression, negated: !@negated)
    end

    def check(state)
      value_tree = @expression.evaluate_tree(state.values)
      evaluation = value_tree[-1]

      if @negated != !evaluation
        rule_context = MessageRuleContext.new(self, state)
        state.errors << message_factory.create(rule_context, value_tree)
      end
    rescue CallError => e
      state.errors << e.message_for_errors(state.actual) unless @negated
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
  end
end
