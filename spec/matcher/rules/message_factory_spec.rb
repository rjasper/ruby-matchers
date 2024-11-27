# frozen_string_literal: true

require 'test_helper'

describe Matcher::MessageFactory do
  let(:exp) do
    expression { _ + vars[:foo] * 2 }
  end

  let(:factory) do
    pattern = Matcher::Pattern.build { hole(:a) + hole(:b) }
    match = pattern.match(exp)
    block = proc { |v, e| report.test(v[:a], v[:b], e[:a], e[:b]) }

    Matcher::MessageFactory
      .new(match.value_paths, match.expressions, block)
  end

  let(:matcher) { Matcher::Base.new }

  it 'passes values and expressions to block' do
    value_tree = exp.evaluate_tree(actual: 1, foo: 2)

    message = factory.create(matcher, value_tree)

    actual = expression { _ }
    foo_times_two = expression { vars[:foo] * 2 }

    assert_equal [1, 4, actual, foo_times_two], message.args
  end

  it 'negates messages' do
    value_tree = exp.evaluate_tree(actual: 4, foo: 2)

    refute factory.create(matcher, value_tree).negated

    factory.negate!

    assert factory.create(matcher, value_tree).negated
  end
end
