# frozen_string_literal: true

require 'test_helper'

describe Matcher::AllMatcher do
  it 'is built by all' do
    matcher = Matcher.build { all(_ > 1, _ < 10) }

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
        error msg(6).described_by('a number divisible by 3')
        error msg(6).described_by('an even number')
      end
    end

    assert_errors matcher.match(9),
      msg(9).not.described_by('an even number')
    assert_no_errors negated.match(9)

    assert_errors matcher.match(4),
      msg(4).not.described_by('a number divisible by 3')
    assert_no_errors negated.match(4)

    assert_errors matcher.match(5),
      msg(5).not.described_by('a number divisible by 3'),
      msg(5).not.described_by('an even number')
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
