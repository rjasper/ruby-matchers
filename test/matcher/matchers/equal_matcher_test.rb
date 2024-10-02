# frozen_string_literal: true

require 'test_helper'

describe Matcher::EqualMatcher do
  it 'matches' do
    matcher = Matcher.build do
      equal(42)
    end

    assert_kind_of Matcher::EqualMatcher, matcher
    assert_predicate matcher.match(42), :valid?
    refute_predicate matcher.match(1), :valid?

    assert_errors matcher.match(23),
      'expected 42 but got 23'
  end

  it '#~' do
    matcher = ~Matcher.build do
      equal(23)
    end

    assert_predicate matcher.match(5), :valid?
    refute_predicate matcher.match(23), :valid?

    assert_errors matcher.match(23),
      'expected 23 to not be 23'
  end

  it '#to_s' do
    matcher = Matcher::EqualMatcher.new(1)

    assert_equal '1', matcher.to_s
    assert_equal 'neg(1)', (~matcher).to_s

    matcher = Matcher::EqualMatcher.new(1..10)
    assert_equal 'equal(1..10)', matcher.to_s
    assert_equal '~equal(1..10)', (~matcher).to_s
  end
end
