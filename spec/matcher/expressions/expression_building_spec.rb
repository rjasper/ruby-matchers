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
end
