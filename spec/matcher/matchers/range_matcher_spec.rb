# frozen_string_literal: true

require 'test_helper'

describe Matcher::RangeMatcher do
  it 'is built from Range' do
    assert_kind_of(Matcher::RangeMatcher, Matcher.build { 1..3 })
  end

  it 'matches Range' do
    matcher = Matcher.build { 1..3 }
    negated = ~matcher

    assert_no_errors matcher.match(2)
    assert_errors negated.match(2),
      msg(2).between(1, 3)

    assert_errors matcher.match(4),
      msg(4).not.between(1, 3)
    assert_no_errors negated.match(4)
  end

  it 'detects uncomparable values' do
    matcher = Matcher.build { 1..3 }
    negated = ~matcher

    assert_errors matcher.match('a'),
      msg('a').not.comparable_to(1)
    assert_no_errors negated.match('a')
  end

  it '#to_s' do
    matcher = Matcher::RangeMatcher.new(1..10)

    assert_equal '1..10', matcher.to_s
    assert_equal 'neg(1..10)', matcher.~.to_s
  end
end
