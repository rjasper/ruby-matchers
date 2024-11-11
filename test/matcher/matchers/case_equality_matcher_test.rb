# frozen_string_literal: true

require 'test_helper'

describe Matcher::CaseEqualityMatcher do
  it '#matches case equality' do
    examine = -> { Matcher::CaseEqualityMatcher.new(_1).match(_2).valid? }

    assert examine.call(String, 'asdf')
    refute examine.call(String, 1)
    assert examine.call(1..3, 2)
    refute examine.call(1..3, 4)
    assert examine.call(/f/, 'foo')
    refute examine.call(/f/, 'bar')
    assert examine.call(Set[1, 2], 1)
    refute examine.call(Set[1, 2], 3)
  end

  it 'generates error messages' do
    assert_expected_errors match('hi') { Integer },
      'expected a kind of Integer but got "hi"'
    assert_expected_errors match('foo') { /bar/ },
      'expected "foo" to match /bar/'
    assert_expected_errors Matcher::CaseEqualityMatcher.new(Set[2, 3]).match(1),
      'expected 1 to be included in #<Set: {2, 3}>'
    assert_expected_errors match(1) { 2..3 },
      'expected value to be between 2 and 3 but got 1'
    assert_expected_errors Matcher::CaseEqualityMatcher.new('foo').match('bar'),
      'expected "foo" but got "bar"'

    assert_expected_errors not_match(1) { Integer },
      'did not expect a kind of Integer but got 1'
    assert_expected_errors not_match('foobar') { /bar/ },
      'did not expect "foobar" to match /bar/'
    assert_expected_errors Matcher::CaseEqualityMatcher.new(Set[2, 3]).~.match(2),
      'did not expect 2 to be included in #<Set: {2, 3}>'
    assert_expected_errors not_match(2) { 1..3 },
      'did not expect value to be between 1 and 3 but got 2'
    assert_expected_errors Matcher::CaseEqualityMatcher.new('foo').~.match('foo'),
      'did not expect "foo"'
  end

  it '#to_s' do
    matcher = Matcher::CaseEqualityMatcher.new(Integer)

    assert_equal 'Integer', matcher.to_s
    assert_equal 'neg(Integer)', (~matcher).to_s
  end
end
