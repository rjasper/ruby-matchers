# frozen_string_literal: true

require 'test_helper'

describe Matcher::LazyAllMatcher do
  it 'is built by lazy_all' do
    matcher = Matcher.build { lazy_all(_ > 1, _ < 10) }

    assert_kind_of Matcher::LazyAllMatcher, matcher
  end

  it 'matches all lazily' do
    matcher = Matcher.build do
      lazy_all(
        satisfy('a number divisible by 3') { _1 % 3 == 0 },
        satisfy('an even number', &:even?),
      )
    end

    negated = ~matcher

    assert matcher.match?(6)
    assert_no_errors matcher.match(6)
    refute negated.match?(6)
    assert_errors negated.match(6),
      msg(6).described_by('an even number')

    refute matcher.match?(9)
    assert_errors matcher.match(9),
      msg(9).not.described_by('an even number')
    assert negated.match?(9)
    assert_no_errors negated.match(9)

    refute matcher.match?(4)
    assert_errors matcher.match(4),
      msg(4).not.described_by('a number divisible by 3')
    assert negated.match?(4)
    assert_no_errors negated.match(4)

    refute matcher.match?(5)
    assert_errors matcher.match(5),
      msg(5).not.described_by('a number divisible by 3')
    assert negated.match?(5)
    assert_no_errors negated.match(5)
  end

  it '#~' do
    matcher = Matcher.build { ~lazy_all(1, 2) }

    assert_equal 'lazy_any(neg(1), neg(2))', matcher.to_s
  end

  it '#&' do
    assert_equal 'lazy_all(1, 2, 3)',
      Matcher.build { lazy_all(1, 2) & 3 }.to_s
    assert_equal 'lazy_all(1, 2, 3)',
      Matcher.build { of(1) & lazy_all(2, 3) }.to_s
    assert_equal 'lazy_all(1, 2)',
      Matcher.build { of(1) & 2 }.to_s
  end

  it '#to_s' do
    matcher = Matcher.build { lazy_all(1, 2) }

    assert_equal 'lazy_all(1, 2)', matcher.to_s
  end
end
