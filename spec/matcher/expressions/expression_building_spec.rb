# frozen_string_literal: true

require 'test_helper'

describe Matcher::ExpressionBuilding do
  it '#assign' do
    matcher = Matcher.build do
      assign { _.foo = 1 }
    end

    expected = Matcher::Call.new(Matcher::Variable.actual, :foo=, [Matcher::Constant.new(1)])

    assert_kind_of Matcher::ExpressionMatcher, matcher
    assert_equal expected, matcher.expression
  end

  it '#assign: +=' do
    matcher = Matcher.build do
      assign { _.foo += 1 }
    end

    operand = expression { _.foo + 1 }
    expected = Matcher::Call.new(Matcher::Variable.actual, :foo=, [operand])

    assert_kind_of Matcher::ExpressionMatcher, matcher
    assert_equal expected,
      matcher.expression
  end

  it '#pass_through_blocks' do
    exp = expression do
      pass_through_blocks { _.map { |x| x ? 2 * x : 0 } }
    end

    assert_equal [2, 4, 6, 0], exp.evaluate(actual: [1, 2, 3, nil])
  end

  it '#declare' do
    matcher = Matcher.build do
      declare foo: 42

      _ + foo == 23
    end

    assert_no_errors matcher.match(-19)
  end
end
