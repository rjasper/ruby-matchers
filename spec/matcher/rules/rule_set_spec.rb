# frozen_string_literal: true

require "test_helper"

describe Matcher::RuleSet do
  let(:context) do
    matcher = Matcher::ExpressionMatcher.new(Matcher::Variable.actual)
    values = Matcher::HashStack.new
    state = Matcher::State.new(values)

    Matcher::MessageRuleContext.new(matcher, state)
  end

  let(:rule_set) { Matcher::RuleSet.new }

  it "returns on message rule" do
    configure do
      transform hole(:x) < hole(:y) do |m|
        call(m[:root], m[:y], :>, m[:x])
      end

      message hole(:x) > hole(:y) do |v|
        "#{v[:x]} greater than #{v[:y]}"
      end
    end

    assert_equal "5 greater than 0", message_for(5) { _ > _ * 2 - 10 }
    assert_equal "2 greater than 1", message_for(1) { _**2 < _ * 2 }
  end

  it "applies multiple transforms" do
    configure do
      # rubocop:disable Style/InverseMethods
      transform !(hole(:x) >= hole(:y)) do |m|
        call(m[:root], m[:x], :<, m[:y])
      end
      # rubocop:enable Style/InverseMethods

      transform (hole(:x) <=> hole(:y)) < 0 do |m|
        call(m[:root], m[:x], :<, m[:y])
      end

      message hole(:any) do |v, e|
        "got #{v[:any]} for #{e[:any]}"
      end
    end

    # rubocop:disable Style/InverseMethods
    assert_equal "got true for actual < 10",
      message_for(5) { !((_ <=> 10) >= 0) }
    # rubocop:enable Style/InverseMethods
  end

  it "negates message after transform" do
    configure do
      transform !hole(:x), negate: true do |m|
        m[:x]
      end

      message hole(:any) do |v|
        standard_message.not_if(v[:any]).truthy
      end
    end

    refute_predicate message_for(true) { _ }, :negated
    assert_predicate message_for(true) { !_ }, :negated
  end

  def configure(&)
    rule_set.configure(&)
  end

  def message_for(actual, &)
    exp = expression(&)
    result = rule_set.apply(exp)
    value_tree = exp.evaluate_tree(actual:)

    assert_kind_of Matcher::MessageFactory, result

    result.create(context, value_tree)
  end
end
