# frozen_string_literal: true

require 'test_helper'

describe Matcher::AllMatcher do
  it 'is built by all' do
    matcher = Matcher.build { all(1) }

    assert_kind_of Matcher::AllMatcher, matcher
  end

  it 'matches all' do
    matcher = Matcher.build do
      all(
        satisfy('a number divisible by 3') { _1 % 3 == 0 },
        satisfy('an even number', &:even?),
      )
    end

    negated = ~matcher

    assert_no_errors matcher.match(6)
    assert_errors negated.match(6) do
      _or do
        error 'did not expect a number divisible by 3 but got 6'
        error 'did not expect an even number but got 6'
      end
    end

    assert_errors matcher.match(9),
      'expected an even number but got 9'
    assert_no_errors negated.match(9)

    assert_errors matcher.match(4),
      'expected a number divisible by 3 but got 4'
    assert_no_errors negated.match(4)

    assert_errors matcher.match(5),
      'expected a number divisible by 3 but got 5',
      'expected an even number but got 5'
    assert_no_errors negated.match(5)
  end

  it '#~' do
    matcher = Matcher.build { ~all(1, 2) }

    assert_equal 'any(neg(1), neg(2))', matcher.to_s
  end

  it '#&' do
    matcher = Matcher.build do
      all(1, 2) & 3
    end

    assert_equal 'all(1, 2, 3)', matcher.to_s
  end

  it '#to_s' do
    matcher = Matcher.build { all(1, 2) }

    assert_equal 'all(1, 2)', matcher.to_s
  end
end
