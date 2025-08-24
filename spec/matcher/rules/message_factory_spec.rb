# frozen_string_literal: true

require 'test_helper'

describe Matcher::MessageFactory do
  let(:exp) do
    expression { _ + vars[:foo] * 2 }
  end

  let(:factory) do
    pattern = Matcher::Pattern.build { hole(:a) + hole(:b) }
    match = pattern.match(exp)
    block = proc { |v, e| standard_message.test(v[:a], v[:b], e[:a], e[:b]) }

    Matcher::MessageFactory
      .new(match.value_paths, match.expressions, block)
  end

  let(:context) do
    matcher = Matcher::ExpressionMatcher.new(Matcher::Variable.actual)
    values = Matcher::HashStack.new
    state = Matcher::State.new(values)

    Matcher::MessageRuleContext.new(matcher, state)
  end

  it 'passes values and expressions to block' do
    value_tree = exp.evaluate_tree(actual: 1, foo: 2)

    message = factory.create(context, value_tree)

    actual = expression { _ }
    foo_times_two = expression { vars[:foo] * 2 }

    assert_equal [1, 4, actual, foo_times_two], message.args
  end

  it 'negates messages' do
    value_tree = exp.evaluate_tree(actual: 4, foo: 2)

    # standard_message is negated by default
    assert factory.create(context, value_tree).negated

    factory.negate!

    refute factory.create(context, value_tree).negated
  end
end
