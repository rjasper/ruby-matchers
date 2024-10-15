# frozen_string_literal: true

require 'test_helper'

describe Matcher::Builder do
  it '#satisfy' do
    matcher = Matcher.build do
      satisfy('square root is bigger than 10') do |actual|
        Math.sqrt(actual) > 10
      end
    end

    assert_predicate matcher.match(1000), :valid?
    refute_predicate matcher.match(10), :valid?
  end

  it '#partial' do
    matcher = Matcher.build do
      partial({ a: 'a' })
    end

    assert_predicate matcher.match({ a: 'a', b: 'b' }), :valid?
  end

  it '#partial_r' do
    matcher = Matcher.build do
      partial_r({ a: { a1: 'a1' } })
    end

    assert_predicate matcher.match({ a: { a1: 'a1', a2: 'a2' }, b: 'b' }), :valid?
  end

  it '#all' do
    matcher = Matcher.build do
      all(_.odd?, _ % 3 == 0)
    end

    assert_predicate matcher.match(3), :valid?
    assert_predicate matcher.match(9), :valid?
    assert_errors matcher.match(6), 'expected _ to be odd but got 6'
    assert_errors matcher.match(7), 'expected _ % 3 to be 0 but got 1 for _ = 7'
  end

  it '#any' do
    matcher = Matcher.build do
      any(_.even?, _ % 5 == 0, 37)
    end

    assert_predicate matcher.match(4), :valid?
    assert_predicate matcher.match(15), :valid?
    assert_predicate matcher.match(37), :valid?
    assert_expected_errors matcher.match(17) do
      _or do
        error 'expected _ to be even but got 17'
        error 'expected _ % 5 to be 0 but got 2 for _ = 17'
        error 'expected 37 but got 17'
      end
    end
  end

  it 'value' do
    matcher = Matcher.build do
      42
    end

    assert_predicate matcher.match(42), :valid?
    refute_predicate matcher.match(23), :valid?
  end

  it 'block' do
    matcher = Matcher.build do
      -> { _1 > 0 }
    end

    assert_predicate matcher.match(10), :valid?
    refute_predicate matcher.match(-1), :valid?
  end

  it 'array' do
    matcher = Matcher.build do
      [1, 2, 3]
    end

    assert_predicate matcher.match([1, 2, 3]), :valid?
    refute_predicate matcher.match([4]), :valid?
  end

  it 'hash' do
    matcher = Matcher.build do
      { a: 1 }
    end

    assert_predicate matcher.match({ a: 1 }), :valid?
    refute_predicate matcher.match({ a: 2 }), :valid?
    refute_predicate matcher.match({ a: 1, b: 2 }), :valid?
  end

  it 'assign' do
    matcher = Matcher.build do
      assign { _.foo = 1 }
    end

    expected = Matcher::Call.new(Matcher::Variable.actual, :foo=, 1)

    assert_kind_of Matcher::ExpressionMatcher, matcher
    assert_equal expected, matcher.expression
  end

  it 'assign: +=' do
    matcher = Matcher.build do
      assign { _.foo += 1 }
    end

    expected = Matcher::Call.new(Matcher::Variable.actual, :foo=, Matcher::Call.build { |_| _.foo + 1 })

    assert_kind_of Matcher::ExpressionMatcher, matcher
    assert_equal expected,
      matcher.expression
  end
end
