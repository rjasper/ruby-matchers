# frozen_string_literal: true

require 'test_helper'

describe Matcher::CaseEqualityMatcher do
  it 'is built from Module, Range, and Regexp' do
    kind = Matcher::CaseEqualityMatcher

    assert_kind_of(kind, Matcher.build { String })
    assert_kind_of(kind, Matcher.build { 1..3 })
    assert_kind_of(kind, Matcher.build { /f/ })
  end

  it 'matches Module' do
    matcher = Matcher.build { String }
    negated = ~matcher

    assert_no_errors matcher.match('asdf')
    assert_errors negated.match('asdf'),
      'did not expect a kind of String but got "asdf"'

    assert_errors matcher.match(1),
      'expected a kind of String but got 1'
    assert_no_errors negated.match(1)
  end

  it 'matches Range' do
    matcher = Matcher.build { 1..3 }
    negated = ~matcher

    assert_no_errors matcher.match(2)
    assert_errors negated.match(2),
      'did not expect value to be between 1 and 3 but got 2'

    assert_errors matcher.match(4),
      'expected value to be between 1 and 3 but got 4'
    assert_no_errors negated.match(4)
  end

  it 'matches Regexp' do
    matcher = Matcher.build { /f/ }
    negated = ~matcher

    assert_no_errors matcher.match('foo')
    assert_errors negated.match('foo'),
      'did not expect value to match /f/ but got "foo"'

    assert_errors matcher.match('bar'),
      'expected value to match /f/ but got "bar"'
    assert_no_errors negated.match('bar')
  end

  it 'matches Set' do
    matcher = Matcher::CaseEqualityMatcher.new(Set[1, 2])
    negated = ~matcher

    assert_no_errors matcher.match(1)
    assert_errors negated.match(1),
      'did not expect object to be included in #<Set: {1, 2}> but got 1'

    assert_errors matcher.match(3),
      'expected object to be included in #<Set: {1, 2}> but got 3'
    assert_no_errors negated.match(3)
  end

  it 'matches other objects' do
    matcher = Matcher::CaseEqualityMatcher.new('foo')
    negated = ~matcher

    assert_no_errors matcher.match('foo')
    assert_errors negated.match('foo'),
      'did not expect "foo"'

    assert_errors matcher.match('bar'),
      'expected "foo" but got "bar"'
    assert_no_errors negated.match('bar')
  end

  it '#to_s' do
    matcher = Matcher::CaseEqualityMatcher.new(Integer)

    assert_equal 'Integer', matcher.to_s
    assert_equal 'neg(Integer)', (~matcher).to_s
  end
end
