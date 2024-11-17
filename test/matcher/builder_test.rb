# frozen_string_literal: true

require 'test_helper'

describe Matcher::Builder do
  it '#satisfy' do
    matcher = Matcher.build do
      satisfy('square root is bigger than 10') do |actual|
        Math.sqrt(actual) > 10
      end
    end

    assert_no_errors matcher.match(1000)
    refute_predicate matcher.match(10), :valid?
  end

  it '#partial' do
    matcher = Matcher.build do
      partial({ a: 'a' })
    end

    assert_no_errors matcher.match({ a: 'a', b: 'b' })
  end

  it '#partial_r' do
    matcher = Matcher.build do
      partial_r({ a: { a1: 'a1' } })
    end

    assert_no_errors matcher.match({ a: { a1: 'a1', a2: 'a2' }, b: 'b' })
  end

  it '#all' do
    matcher = Matcher.build do
      all(_.odd?, _ % 3 == 0)
    end

    assert_no_errors matcher.match(3)
    assert_no_errors matcher.match(9)
    assert_expected_errors matcher.match(6), 'expected value to be odd but got 6'
    assert_expected_errors matcher.match(7), 'expected _ % 3 == 0 but got 1 == 0, where _ = 7'
  end

  it '#any' do
    matcher = Matcher.build do
      any(_.even?, _ % 5 == 0, 37)
    end

    assert_no_errors matcher.match(4)
    assert_no_errors matcher.match(15)
    assert_no_errors matcher.match(37)
    assert_expected_errors matcher.match(17) do
      _or do
        error 'expected value to be even but got 17'
        error 'expected _ % 5 == 0 but got 2 == 0, where _ = 17'
        error 'expected 37 but got 17'
      end
    end
  end

  it 'value' do
    matcher = Matcher.build do
      42
    end

    assert_no_errors matcher.match(42)
    refute_predicate matcher.match(23), :valid?
  end

  it 'block' do
    matcher = Matcher.build do
      -> { _1 > 0 }
    end

    assert_no_errors matcher.match(10)
    refute_predicate matcher.match(-1), :valid?
  end

  it 'array' do
    matcher = Matcher.build do
      [1, 2, 3]
    end

    assert_no_errors matcher.match([1, 2, 3])
    refute_predicate matcher.match([4]), :valid?
  end

  it 'hash' do
    matcher = Matcher.build do
      { a: 1 }
    end

    assert_no_errors matcher.match({ a: 1 })
    refute_predicate matcher.match({ a: 2 }), :valid?
    refute_predicate matcher.match({ a: 1, b: 2 }), :valid?
  end

  it 'assign' do
    matcher = Matcher.build do
      assign { _.foo = 1 }
    end

    expected = Matcher::Call.new(Matcher::Variable.actual, :foo=, [Matcher::Constant.new(1)])

    assert_kind_of Matcher::ExpressionMatcher, matcher
    assert_equal expected, matcher.expression
  end

  it 'assign: +=' do
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
