# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

describe Matcher::AllMatcher do
  it 'match all' do
    divisible_by_three = Matcher::BlockMatcher.new(-> { _1 % 3 == 0 }, 'a number divisible by 3')
    even = Matcher::BlockMatcher.new(-> { _1.even? }, 'an even number')
    matcher = Matcher::AllMatcher.new([divisible_by_three, even])

    assert_predicate matcher.match(6), :valid?
    refute_predicate matcher.match(9), :valid?
    refute_predicate matcher.match(4), :valid?

    assert_errors matcher.match(5),
      'expected a number divisible by 3 but got 5',
      'expected an even number but got 5'
  end

  it '#&' do
    matcher = Matcher::AllMatcher.new([v(1), v(2)]) & v(3)

    assert_equal 'all(1, 2, 3)', matcher.to_s
  end

  it '#to_s' do
    matcher = Matcher::AllMatcher.new([v(1), v(2)])

    assert_equal 'all(1, 2)', matcher.to_s
    assert_equal 'any(neg(1), neg(2))', (~matcher).to_s
  end
end
