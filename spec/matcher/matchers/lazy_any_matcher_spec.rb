# frozen_string_literal: true

require 'test_helper'

describe Matcher::LazyAnyMatcher do
  it 'is built by lazy_any' do
    matcher = Matcher.build { lazy_any(_.even?, _ % 3 == 0) }

    assert_kind_of Matcher::LazyAnyMatcher, matcher
  end

  it 'matches any lazily' do
    matcher = Matcher.build { lazy_any(1, 2) }
    negated = ~matcher

    assert matcher.match?(1)
    assert_no_errors matcher.match(1)
    refute negated.match?(1)
    assert_errors negated.match(1), msg(1).equal(1)

    assert matcher.match?(2)
    assert_no_errors matcher.match(2)
    refute negated.match?(2)
    assert_errors negated.match(2), msg(2).equal(2)

    refute matcher.match?(4)
    assert_errors matcher.match(4), msg(4).not.equal(2)
    assert negated.match?(4)
    assert_no_errors negated.match(4)
  end

  it '#~' do
    matcher = Matcher.build { ~lazy_any(1, 2) }

    assert_equal 'lazy_all(neg(1), neg(2))', matcher.to_s
  end

  it '#|' do
    assert_equal 'lazy_any(1, 2, 3)',
      Matcher.build { lazy_any(1, 2) | 3 }.to_s
    assert_equal 'lazy_any(1, 2, 3)',
      Matcher.build { of(1) | lazy_any(2, 3) }.to_s
    assert_equal 'lazy_any(1, 2)',
      Matcher.build { of(1) | 2 }.to_s
  end

  it '#to_s' do
    matcher = Matcher.build { lazy_any(1, 2) }

    assert_equal 'lazy_any(1, 2)', matcher.to_s
  end
end
