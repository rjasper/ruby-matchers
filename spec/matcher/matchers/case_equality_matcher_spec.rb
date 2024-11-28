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
      msg('asdf').kind_of(String)

    assert_errors matcher.match(1),
      msg(1).not.kind_of(String)
    assert_no_errors negated.match(1)
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

  it 'matches Regexp' do
    matcher = Matcher.build { /f/ }
    negated = ~matcher

    assert_no_errors matcher.match('foo')
    assert_errors negated.match('foo'),
      msg('foo').matching(/f/)

    assert_errors matcher.match('bar'),
      msg('bar').not.matching(/f/)
    assert_no_errors negated.match('bar')
  end

  it 'matches Set' do
    matcher = Matcher::CaseEqualityMatcher.new(Set[1, 2])
    negated = ~matcher

    assert_no_errors matcher.match(1)
    assert_errors negated.match(1),
      msg(1).in(Set[1, 2])

    assert_errors matcher.match(3),
      msg(3).not.in(Set[1, 2])
    assert_no_errors negated.match(3)
  end

  it 'matches other objects' do
    matcher = Matcher::CaseEqualityMatcher.new('foo')
    negated = ~matcher

    assert_no_errors matcher.match('foo')
    assert_errors negated.match('foo'),
      msg('foo').equal('foo')

    assert_errors matcher.match('bar'),
      msg('bar').not.equal('foo')
    assert_no_errors negated.match('bar')
  end

  it '#to_s' do
    matcher = Matcher::CaseEqualityMatcher.new(Integer)

    assert_equal 'Integer', matcher.to_s
    assert_equal 'neg(Integer)', (~matcher).to_s
  end
end
