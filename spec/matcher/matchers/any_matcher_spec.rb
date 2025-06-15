# frozen_string_literal: true

require 'test_helper'

describe Matcher::AnyMatcher do
  it 'is built by any' do
    matcher = Matcher.build { any(_.even?, _ % 3 == 0) }

    assert_kind_of Matcher::AnyMatcher, matcher
  end

  it 'matches any' do
    matcher = Matcher.build { any(1, 2) }
    negated = ~matcher

    assert_no_errors matcher.match(1)
    assert_errors negated.match(1),
      msg(1).equal(1)

    assert_no_errors matcher.match(2)
    assert_errors negated.match(2),
      msg(2).equal(2)

    assert_errors matcher.match(4) do
      _or do
        error msg(4).not.equal(1)
        error msg(4).not.equal(2)
      end
    end
    assert_no_errors negated.match(4)
  end

  it '#~' do
    matcher = Matcher.build { ~any(1, 2) }

    assert_equal 'all(neg(1), neg(2))', matcher.to_s
  end

  it '#|' do
    matcher = Matcher.build { any(1, 2) | 3 }

    assert_equal 'any(1, 2, 3)', matcher.to_s
  end

  it '#to_s' do
    matcher = Matcher.build { any(1, 2) }

    assert_equal 'any(1, 2)', matcher.to_s
  end
end
